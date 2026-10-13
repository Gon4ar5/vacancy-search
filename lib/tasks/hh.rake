namespace :hh do
  desc "Import up to 10 pages of hh.ru vacancies for Belarus"
  task import: :environment do
    job = Hh::ImportVacanciesJob.perform_later
    puts "Enqueued hh.ru import job #{job.job_id}."
  end
end
