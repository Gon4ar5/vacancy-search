module Rag
  class IndexVacancyJob < ApplicationJob
    # джоба для разбиения на фрагменты и сохрария вектора в бд
    def perform(job_id)
      job = Job.find_by(id: job_id)
      return unless job

      IndexJobs.new([job]).call
    end
  end
end
