namespace :rag do
  desc "Create or refresh embeddings for all saved vacancies"
  task index_jobs: :environment do
    indexed = Job.find_in_batches(batch_size: 20).sum { |jobs| Rag::IndexJobs.new(jobs).call }
    puts "Indexed #{indexed} new or updated vacancy fragments."
  end
end
