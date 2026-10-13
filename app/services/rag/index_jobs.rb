module Rag
  class IndexJobs
    def initialize(jobs, client: Ai::OpenaiClient.new)
      @jobs = jobs
      @client = client
    end

    def call
      changed = @jobs.filter_map do |job|
        chunks = Chunker.call(job)
        next if chunks.empty?

        digests = chunks.map { |content| Chunker.digest(content) }
        next if job.job_chunks.order(:chunk_index).pluck(:content_digest) == digests

        [job, chunks, digests]
      end
      return 0 if changed.empty?

      content = changed.flat_map { |_job, chunks, _digests| chunks }
      vectors = @client.embeddings(content)
      vector_index = 0

      JobChunk.transaction do
        changed.each do |job, chunks, digests|
          job.job_chunks.delete_all
          chunks.each_with_index do |chunk, index|
            job.job_chunks.create!(
              chunk_index: index,
              content: chunk,
              content_digest: digests[index],
              embedding: vectors.fetch(vector_index)
            )
            vector_index += 1
          end
        end
      end

      content.size
    end
  end
end
