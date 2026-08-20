require "rails_helper"

RSpec.describe Hh::ImportVacancies do
  class FixtureHhImporter < Hh::ImportVacancies
    attr_reader :listing_pages

    def initialize(documents)
      @documents = documents
      @listing_pages = []
      super()
    end

    private

    def fetch_document(uri)
      unless uri.path == "/search/vacancy"
        return @documents.fetch(uri.path)
      end

      page = URI.decode_www_form(uri.query).to_h.fetch("page").to_i
      @listing_pages << page
      @documents.fetch([ :listing, page ])
    end
  end

  before do
    Job.delete_all
    SourceImportState.delete_all
  end

  let(:source) { "hh.ru (all Belarus vacancies)" }

  it "reads each listing page and saves its job descriptions" do
    cards = 20.times.map { |index| vacancy_card(index + 1) }
    documents = { [ :listing, 0 ] => page(cards), [ :listing, 1 ] => page([ vacancy_card(21) ]) }
    (1..21).each { |id| documents["/vacancy/#{id}"] = details("Description #{id}") }
    importer = FixtureHhImporter.new(documents)

    importer.call

    expect(importer.listing_pages).to eq([ 0, 1 ])
    expect(Job.where(source: source).length).to eq(21)
    expect(Job.find_by!(external_id: "1").description).to eq("Description 1")
    expect(SourceImportState.find_by!(source: "hh.ru (all Belarus vacancies)").initial_import_completed_at).to be_present
  end

  it "stops on the first saved job after the initial import" do
    Job.create!(title: "Already saved", source: "hh.ru (all Belarus vacancies)", source_url: "https://hh.ru/vacancy/1")
    SourceImportState.create!(source: "hh.ru (all Belarus vacancies)", initial_import_completed_at: Time.current)
    importer = FixtureHhImporter.new({ [ :listing, 0 ] => page([ vacancy_card(1), vacancy_card(2) ]) })

    result = importer.call

    expect(importer.listing_pages).to eq([ 0 ])
    expect(result.stopped_at_duplicate).to be(true)
    expect(Job.exists?(source_url: "https://hh.ru/vacancy/2")).to be(false)
  end

  def vacancy_card(id)
    <<~HTML
      <article data-qa="vacancy-serp__vacancy">
        <a data-qa="serp-item__title" href="/vacancy/#{id}?from=search">Developer #{id}</a>
        <span data-qa="vacancy-serp__vacancy-employer-text">Acme</span>
      </article>
    HTML
  end

  def page(cards)
    Nokogiri::HTML(cards.join)
  end

  def details(description)
    Nokogiri::HTML("<div data-qa='vacancy-description'>#{description}</div>")
  end
end
