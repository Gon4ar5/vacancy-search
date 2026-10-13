require "rails_helper"

RSpec.describe Job, type: :model do
  it "requires a title, source and source URL" do
    job = described_class.new

    expect(job).not_to be_valid
    expect(job.errors.attribute_names).to contain_exactly(:title, :source, :source_url)
  end

  it "keeps source URLs unique per source" do
    described_class.create!(title: "Rails developer", source: "hh.ru", source_url: "https://hh.ru/vacancy/123")
    duplicate = described_class.new(title: "Another title", source: "hh.ru", source_url: "https://hh.ru/vacancy/123")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:source_url]).to include("has already been taken")
  end
end
