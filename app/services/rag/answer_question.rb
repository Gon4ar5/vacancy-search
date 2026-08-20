module Rag
  class AnswerQuestion
    Result = Struct.new(:answer, :sources, keyword_init: true)
    LIMIT = 6

    def initialize(question, client: Ai::OpenaiClient.new)
      @question = question
      @client = client
    end

    def call
      query_vector = @client.embeddings([ @question ]).first
      chunks = JobChunk.nearest_neighbors(:embedding, query_vector, distance: "cosine")
        .joins(:job)
        .where.not(embedding: nil)
        .includes(:job)
        .limit(LIMIT)

      return Result.new(answer: "Пока нет проиндексированных вакансий. Сначала запустите индексацию.", sources: []) if chunks.empty?

      sources = chunks.map(&:job).uniq
      source_numbers = sources.each_with_index.to_h { |job, index| [ job.id, index + 1 ] }
      context = chunks.map do |chunk|
        job = chunk.job
        "[#{source_numbers.fetch(job.id)}] #{job.title} — #{job.company_name}\n" \
          "Источник: #{job.source_url}\nФрагмент: #{chunk.content}"
      end.join("\n\n")

      Result.new(answer: @client.answer(question: @question, context: context), sources: sources)
    end
  end
end
