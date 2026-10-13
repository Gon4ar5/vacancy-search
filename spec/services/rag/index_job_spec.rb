require "rails_helper"

RSpec.describe Rag::IndexJob do
  let(:job) do
    Job.create!(
      title: "Rails developer",
      company_name: "Acme",
      source: "hh.ru",
      source_url: "https://hh.ru/vacancy/123",
      description: "Build Rails applications and APIs."
    )
  end
  let(:client) { instance_double(Ai::OpenaiClient, embeddings: [Array.new(1_536, 0.1)]) }

  it "stores chunks with their embeddings and source job" do
    expect { described_class.new(job, client: client).call }.to change(JobChunk, :count).by(1)

    chunk = JobChunk.last
    expect(chunk.job).to eq(job)
    expect(chunk.content).to include("Rails developer", "Build Rails applications")
    expect(chunk.content_digest).to be_present
  end

  it "does not request embeddings again when the source text is unchanged" do
    service = described_class.new(job, client: client)
    service.call

    expect(client).not_to receive(:embeddings)
    expect(service.call).to eq(0)
  end
end
