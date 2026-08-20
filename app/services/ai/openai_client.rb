require "net/http"
require "json"

module Ai
  class OpenaiClient
    class Error < StandardError; end

    API_ROOT = "https://api.openai.com/v1"
    EMBEDDING_MODEL = "text-embedding-3-small"
    CHAT_MODEL = "gpt-4o-mini"

    def embeddings(texts)
      response = post("/embeddings", model: EMBEDDING_MODEL, input: texts)
      response.fetch("data").sort_by { |item| item.fetch("index") }.map { |item| item.fetch("embedding") }
    end

    def answer(question:, context:)
      response = post(
        "/chat/completions",
        model: CHAT_MODEL,
        temperature: 0.2,
        messages: [
          {
            role: "system",
            content: "Отвечай по-русски, используя только переданные фрагменты вакансий. " \
              "Если данных недостаточно, скажи об этом. Подтверждай каждое утверждение ссылкой вида [1], " \
              "где номер соответствует источнику в контексте. Не выдумывай статистику и требования."
          },
          { role: "user", content: "Вопрос: #{question}\n\nФрагменты и источники:\n#{context}" }
        ]
      )

      response.dig("choices", 0, "message", "content").presence || "Не удалось сформировать ответ."
    end

    private

    def post(path, payload)
      api_key = ENV["OPENAI_API_KEY"].presence
      raise Error, "Нужно задать OPENAI_API_KEY" unless api_key

      uri = URI("#{API_ROOT}#{path}")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{api_key}"
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(payload)

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 60) do |http|
        http.request(request)
      end
      body = JSON.parse(response.body)
      return body if response.is_a?(Net::HTTPSuccess)

      message = body.dig("error", "message") || "HTTP #{response.code}"
      raise Error, "OpenAI API error: #{message}"
    end
  end
end
