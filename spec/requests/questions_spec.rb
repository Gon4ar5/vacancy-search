require "rails_helper"

RSpec.describe "Questions", type: :request do
  let(:browser_headers) do
    {
      "HTTP_USER_AGENT" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36",
      "HTTP_ORIGIN" => "http://localhost"
    }
  end

  before { host! "localhost" }

  it "shows a generated answer and its source vacancy" do
    job = Job.create!(title: "Rails developer", source: "hh.ru", source_url: "https://hh.ru/vacancy/123")
    result = Rag::AnswerQuestion::Result.new(answer: "Нужен Ruby on Rails [1].", sources: [ job ])
    allow(Rag::AnswerQuestion).to receive(:new).and_return(instance_double(Rag::AnswerQuestion, call: result))
    get new_question_path, headers: browser_headers
    post question_path, params: { question: "Какие навыки нужны?" }, headers: browser_headers

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Нужен Ruby on Rails [1].", "https://hh.ru/vacancy/123")
  end
end
