# frozen_string_literal: true

namespace :server_job do
  desc 'Reattach result zips'
  task reattach_results: :environment do |_t|
    PpgJob.find_each(batch_size: 1000) do |ppg_job|
      id = ppg_job.id
      ppg_job.result_zip.destroy
      ppg_job.result_zip.attach(io: File.open("#{Dir.home}/server_jobs/ppg_scorer/#{id}/#{id}_results.zip"), filename: "#{id}.zip")
    end

    BlastJob.find_each(batch_size: 1000) do |blast_job|
      id = blast_job.id
      blast_job.result_zip.destroy
      blast_job.result_zip.attach(io: File.open("#{Dir.home}/server_jobs/blast/#{id}/#{id}_results.zip"), filename: "#{id}.zip")
    end
  end
end

