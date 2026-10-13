namespace :hirify do
  desc "Import Hirify pages until the end, or stop at the first existing vacancy after the initial scan"
  task import: :environment do
    job = Hirify::ImportVacanciesJob.perform_later
    puts "Enqueued full Hirify import job #{job.job_id}."
  end
end
