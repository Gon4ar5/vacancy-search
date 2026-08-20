require "net/http"
require "nokogiri"
require "set"
require "time"
require "uri"

module HabrCareer
  class ImportVacancies
    BASE_URL = "https://career.habr.com".freeze
    SOURCE = "Habr Career".freeze
    CATEGORY = "all"
    DETAIL_REQUEST_DELAY = 1.0

    def self.call
      new.call
    end

    def initialize
      @detail_requests = 0
    end

    def call
      listing_url = first_page_url
      visited_urls = Set.new

      loop do
        raise Error, "Habr Career pagination repeated #{listing_url}" if visited_urls.include?(listing_url.to_s)

        visited_urls.add(listing_url.to_s)
        document = fetch_document(listing_url)
        cards = document.css(".vacancy-card")
        raise Error, "Habr Career page layout changed: vacancy cards were not found" if cards.empty?

        cards.each { |card| import_card(card) }

        next_link = document.at_css('.pagination a[rel~="next"]')
        break unless next_link

        listing_url = URI.join(BASE_URL, next_link["href"])
        validate_listing_url!(listing_url)
      end
    end

    class Error < StandardError; end

    private

    def first_page_url
      URI.join(BASE_URL, "/vacancies?page=1&type=#{CATEGORY}")
    end

    def validate_listing_url!(uri)
      valid_path = uri.path.match?(%r{\A/vacancies(?:/[a-z0-9_-]+)?\z})
      return if uri.scheme == "https" && uri.host == "career.habr.com" && valid_path

      raise Error, "unexpected Habr Career pagination URL: #{uri}"
    end

    def import_card(card)
      title_link = card.at_css(".vacancy-card__title-link")
      title = title_link&.text&.strip
      relative_url = title_link&.[]("href")
      company_name = card.at_css(".vacancy-card__company a")&.text&.strip

      unless title.present? && relative_url.present?
        return
      end

      source_url = URI.join(BASE_URL, relative_url).to_s
      unless source_url.start_with?("#{BASE_URL}/vacancies/")
        return
      end

      published_at = parse_publication_time(card.at_css(".vacancy-card__date time")&.[]("datetime"))

      posting = Job.find_or_initialize_by(source: SOURCE, source_url:)
      created = posting.new_record?
      description = fetch_description(source_url) if created || posting.description.blank?
      posting.assign_attributes(
        title:,
        company_name: company_name.presence,
        external_id: source_url[%r{/vacancies/(\d+)}, 1],
        description: description.presence || posting.description,
        published_at: published_at || posting.published_at
      )

      if posting.changed?
        posting.save!
      end
    rescue ActiveRecord::RecordInvalid, URI::InvalidURIError
    end

    def fetch_description(url)
      sleep DETAIL_REQUEST_DELAY if @detail_requests.positive?
      @detail_requests += 1
      document = fetch_document(URI(url))
      document.at_css(".vacancy-description__text")&.inner_text&.gsub(/[ \t]+\n/, "\n")&.gsub(/\n{3,}/, "\n\n")&.strip
    rescue Error
      nil
    end

    def fetch_document(uri)
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "Mozilla/5.0 (compatible; vacancy-aggregator/0.1)"
      request["Accept"] = "text/html"

      response = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: 10,
        read_timeout: 20
      ) { |http| http.request(request) }

      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "Habr Career returned HTTP #{response.code} for #{uri}"
      end

      Nokogiri::HTML(response.body)
    rescue SocketError, Timeout::Error, IOError, SystemCallError => error
      raise Error, "request failed (#{error.class})"
    end

    def parse_publication_time(value)
      Time.iso8601(value) if value.present?
    rescue ArgumentError
      nil
    end
  end
end
