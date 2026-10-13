require "rails_helper"

RSpec.describe "Jobs", type: :request do
  let(:browser_headers) do
    {
      "HTTP_USER_AGENT" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36",
      "HTTP_ORIGIN" => "http://localhost"
    }
  end

  before do
    host! "localhost"
  end

  it "lists jobs on the home page" do
    Job.create!(title: "Rails developer", source: "hh.ru", source_url: "https://hh.ru/vacancy/123")

    get root_path, headers: browser_headers

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Rails developer")
  end

  it "creates a job" do
    expect do
      post jobs_path, params: {
        job: { title: "Rails developer", source: "hh.ru", source_url: "https://hh.ru/vacancy/123" }
      }, headers: browser_headers
    end.to change(Job, :count).by(1)

    expect(response).to have_http_status(:found)
    expect(response).to redirect_to(job_path(Job.last))
  end
end
