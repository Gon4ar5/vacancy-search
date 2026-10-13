require "rails_helper"

RSpec.describe HabrCareer::ImportVacancies do
  class FixtureHabrImporter < HabrCareer::ImportVacancies
    attr_reader :requested_urls

    def initialize(documents)
      @documents = documents
      @requested_urls = []
      super()
    end

    private

    def fetch_document(uri)
      @requested_urls << uri.to_s
      @documents.fetch(uri.to_s)
    end
  end

  before do
    Job.delete_all
  end

  it "follows Habr pagination and saves vacancy details" do
    first_page = "https://career.habr.com/vacancies?page=1&type=all"
    second_page = "https://career.habr.com/vacancies?page=2&type=all"
    first_listing = Nokogiri::HTML(<<~HTML)
      <div class="vacancy-card">
        <a class="vacancy-card__title-link" href="/vacancies/101-ruby">Ruby developer</a>
        <div class="vacancy-card__company"><a>Acme</a></div>
      </div>
      <div class="pagination"><a rel="next" href="/vacancies?page=2&amp;type=all">Next</a></div>
    HTML
    second_listing = Nokogiri::HTML(<<~HTML)
      <div class="vacancy-card">
        <a class="vacancy-card__title-link" href="/vacancies/202-rails">Rails developer</a>
      </div>
    HTML
    detail_101 = Nokogiri::HTML('<div class="vacancy-description__text">Build Rails apps</div>')
    detail_202 = Nokogiri::HTML('<div class="vacancy-description__text">Maintain Rails apps</div>')
    importer = FixtureHabrImporter.new(
      first_page => first_listing,
      second_page => second_listing,
      "https://career.habr.com/vacancies/101-ruby" => detail_101,
      "https://career.habr.com/vacancies/202-rails" => detail_202
    )

    importer.call

    expect(importer.requested_urls).to eq([
      first_page,
      "https://career.habr.com/vacancies/101-ruby",
      second_page,
      "https://career.habr.com/vacancies/202-rails"
    ])
    expect(Job.where(source: "Habr Career").count).to eq(2)
    expect(Job.find_by!(external_id: "101").description).to eq("Build Rails apps")
  end
end
