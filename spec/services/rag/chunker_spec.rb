require "rails_helper"

RSpec.describe Rag::Chunker do
  it "includes the vacancy title and company in the searchable text" do
    job = Job.new(title: "Rails developer", company_name: "Acme", description: "Build web applications")

    expect(described_class.call(job).join).to include("Rails developer", "Acme", "Build web applications")
  end

  it "keeps each chunk within the configured size" do
    job = Job.new(title: "Rails developer", description: "Ruby " * 800)

    expect(described_class.call(job).map(&:length)).to all(be <= described_class::MAX_LENGTH)
  end
end
