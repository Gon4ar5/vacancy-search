require "net/http"
require "nokogiri"
require "set"
require "uri"

module Hh
  class ImportVacancies
    BASE_URL = "https://hh.ru".freeze
    AREA = "16"
    PAGE_LIMIT = 10
    MAX_PAGES = 100
    DETAIL_REQUEST_DELAY = 1.5

    Result = Struct.new(:stopped_at_duplicate, keyword_init: true)

    def self.call
      new.call
    end

    def initialize
      @source = "hh.ru (all Belarus vacancies)"
      @state = SourceImportState.find_or_create_by!(source: @source)
      @initial_import_complete = @state.initial_import_completed_at.present?
      @known_urls = @initial_import_complete ? Job.where(source: @source).pluck(:source_url).to_set : Set.new
      @seen_urls = Set.new
      @detail_requests = 0
      @result = Result.new(stopped_at_duplicate: false)
    end

    def call
      page_number = 0
      loop do
        document = fetch_document(listing_uri(page_number))
        cards = document.css('article[data-qa="vacancy-serp__vacancy"]')
        break if cards.empty?

        cards.each do |card|
          outcome = import_card(card)
          break if outcome == :stop
        end

        imported_pages = page_number + 1
        break if @result.stopped_at_duplicate || imported_pages >= PAGE_LIMIT || cards.length < 20

        page_number += 1
        raise Error, "hh.ru pagination exceeded #{MAX_PAGES} pages" if page_number >= MAX_PAGES
      end

      @state.update!(initial_import_completed_at: Time.current) unless @initial_import_complete
      @result
    end

    class Error < StandardError; end

    private

    def listing_uri(page_number)
      params = { area: AREA, page: page_number }
      URI("#{BASE_URL}/search/vacancy?#{URI.encode_www_form(params)}")
    end

    def import_card(card)
      title_link = card.at_css('a[data-qa="serp-item__title"]')
      title = title_link&.text&.strip
      url = valid_vacancy_url(title_link&.[]("href"))
      unless title.present? && url
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

      posting = Job.find_or_initialize_by(source: @source, source_url: url)
      created = posting.new_record?
      document = fetch_document(URI(url)) if created || posting.description.blank?
      company = card.at_css('[data-qa="vacancy-serp__vacancy-employer-text"]')&.text&.strip ||
        card.at_css('[data-qa="vacancy-serp__vacancy-employer"]')&.text&.strip
      description = document&.at_css('[data-qa="vacancy-description"]')&.inner_text&.gsub(/[ \t]+\n/, "\n")&.gsub(/\n{3,}/, "\n\n")&.strip

      posting.assign_attributes(
        title:,
        company_name: company.presence,
        external_id: url[%r{/vacancy/(\d+)}, 1],
        description: description.presence || posting.description
      )

      if posting.changed?
        posting.save!
      end
    rescue ActiveRecord::RecordInvalid
    rescue ActiveRecord::RecordNotUnique
    rescue URI::InvalidURIError
    end

    def valid_vacancy_url(value)
      return if value.blank?

      uri = URI.join(BASE_URL, value)
      uri.query = nil
      uri.to_s if uri.scheme == "https" && uri.host == "hh.ru" && uri.path.match?(%r{\A/vacancy/\d+\z})
    rescue URI::InvalidURIError
      nil
    end

    def fetch_document(uri)
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "Mozilla/5.0 (compatible; vacancy-aggregator/0.1)"
      request["Accept"] = "text/html"
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) do |http|
        http.request(request)
      end
      raise Error, "hh.ru returned HTTP #{response.code} for #{uri}" unless response.is_a?(Net::HTTPSuccess)

      sleep DETAIL_REQUEST_DELAY if uri.path.start_with?("/vacancy/") && @detail_requests.positive?
      @detail_requests += 1 if uri.path.start_with?("/vacancy/")
      document = Nokogiri::HTML(response.body)
      if document.at_css('[data-qa="error-message"]')&.text&.match?(/captcha|капч/i)
        raise Error, "hh.ru returned a CAPTCHA page for #{uri}"
      end
      document
    rescue SocketError, Timeout::Error, IOError, SystemCallError => error
      raise Error, "hh.ru request failed (#{error.class})"
    end
  end
end
