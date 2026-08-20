module Rag
  class IndexJob
    def initialize(job, client: Ai::OpenaiClient.new)
      @job = job
      @client = client
    end

    def call
      IndexJobs.new([ @job ], client: @client).call
    end
  end
end
