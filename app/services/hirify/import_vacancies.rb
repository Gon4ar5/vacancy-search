require "net/http"
require "nokogiri"
require "set"
require "uri"

module Hirify
  class ImportVacancies
    BASE_URL = "https://hirify.me".freeze
    SOURCE = "Hirify".freeze
    PAGE_SIZE = 20
    DETAIL_REQUEST_DELAY = 2.0

    Result = Struct.new(:stopped_at_duplicate, keyword_init: true)

    def self.call
      new.call
    end

    def initialize
      @state = SourceImportState.find_or_create_by!(source: SOURCE)
      @initial_import_complete = @state.initial_import_completed_at.present?
      @known_urls = if @initial_import_complete
        Job.where(source: SOURCE).pluck(:source_url).to_set
      else
        Set.new
      end
      @seen_urls = Set.new
      @seen_pages = Set.new
      @detail_requests = 0
      @result = Result.new(stopped_at_duplicate: false)
    end

    def call
      page_number = 1

      loop do
        document = fetch_document(listing_uri(page_number))
        cards = document.css("a.vacancy-card-link[href^='/jobs/']").first(PAGE_SIZE)
        break if cards.empty?

        page_urls = cards.filter_map { |card| valid_job_url(card["href"]) }
        page_signature = page_urls.join("|")
        break if @seen_pages.include?(page_signature)

        @seen_pages.add(page_signature)
        cards.each do |card|
          outcome = import_card(card, valid_job_url(card["href"]))
          break if outcome == :stop
        end

        break if @result.stopped_at_duplicate || cards.length < PAGE_SIZE

        page_number += 1
      end

      @state.update!(initial_import_completed_at: Time.current) unless @initial_import_complete
      @result
    end

    class Error < StandardError; end

    private

    def listing_uri(page_number)
      path = page_number == 1 ? "/" : "/?page=#{page_number}"
      URI.join(BASE_URL, path)
    end

    def import_card(card, url)
      unless url
        return
      end

      if @known_urls.include?(url)
        @result.stopped_at_duplicate = true
        return :stop
      end

      if @seen_urls.include?(url)
        return
      end
      @seen_urls.add(url)

      posting = Job.find_or_initialize_by(source: SOURCE, source_url: url)
      created = posting.new_record?
      @last_document = nil
      description = fetch_description(url) if created || posting.description.blank?
      document = @last_document
      title = card.at_css(".title")&.text&.strip || document&.at_css("h1")&.text&.strip || posting.title.presence || title_from_url(url)
      company = card.at_css(".company")&.text&.strip || document&.at_css(".blurred-company")&.text&.strip || posting.company_name

      posting.assign_attributes(
        title:,
        company_name: company.presence,
        external_id: url[%r{/jobs/(\d+)}, 1],
        description: description.presence || posting.description
      )

      if posting.changed?
        posting.save!
      end
    rescue ActiveRecord::RecordInvalid
    end

    def fetch_description(url)
      sleep DETAIL_REQUEST_DELAY if @detail_requests.positive?
      @detail_requests += 1
      @last_document = fetch_document(URI(url))
      @last_document.at_css(".description")&.inner_text&.gsub(/[ \t]+\n/, "\n")&.gsub(/\n{3,}/, "\n\n")&.strip ||
        @last_document.at_css('meta[name="description"]')&.[]("content")
    rescue Error
      @last_document = nil
      nil
    end

    def fetch_document(uri)
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "Mozilla/5.0 (compatible; vacancy-aggregator/0.1)"
      request["Accept"] = "text/html,application/xml,text/xml"

      response = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: 10,
        read_timeout: 30
      ) { |http| http.request(request) }

      raise Error, "Hirify returned HTTP #{response.code} for #{uri}" unless response.is_a?(Net::HTTPSuccess)

      Nokogiri::HTML(response.body)
    rescue SocketError, Timeout::Error, IOError, SystemCallError => error
      raise Error, "Hirify request failed (#{error.class})"
    end

    def valid_job_url(value)
      uri = URI.join(BASE_URL, value.to_s)
      return uri.to_s if uri.scheme == "https" && uri.host == "hirify.me" && uri.path.match?(%r{\A/jobs/\d+[a-zA-Z0-9-]*\z})

      nil
    rescue URI::InvalidURIError
      nil
    end

    def title_from_url(url)
      url.split("/").last.to_s.sub(/\A\d+-/, "").tr("-", " ").titleize
    end
  end
end
