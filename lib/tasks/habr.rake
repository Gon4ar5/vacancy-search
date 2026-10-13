namespace :habr do
  desc "Import all Habr Career vacancies"
  task import: :environment do
    job = HabrCareer::ImportVacanciesJob.perform_later
    puts "Enqueued Habr Career import job #{job.job_id}."
  end
end
