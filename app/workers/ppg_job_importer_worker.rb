# frozen_string_literal: true
require 'zip'

class PpgJobImporterWorker
  include Sidekiq::Worker

  def perform(job_id, results_path)
    @ppg_job = PpgJob.find(job_id)
    @result_zip_path = "#{results_path}/#{job_id}.zip"
    @local_results_dir = "#{Dir.home}/server_jobs/ppg_scorer/#{job_id}"
    @local_zip_path = "#{@local_results_dir}/#{job_id}_results.zip"

    import_results(job_id)
    @ppg_job.result_zip.attach(io: File.open(@local_zip_path), filename: "#{job_id}.zip")
    load_functionality_scores(job_id)

    @ppg_job.update(status: 'finished')
    send_mail(job_id)
    remove_remote_dir(results_path)
  end

  def import_results(job_id)
    Net::SSH.start(Rails.application.credentials[:xylocalyx_ip], 'lara', keys: ['/home/warpp/.ssh/xylocalyx']) do |session|
      # Download result file
      session.scp.download!(@result_zip_path, @local_zip_path)

      # unzip result
      Zip::File.open(@local_zip_path) do |zip_file|
        zip_file.each do |entry|
          entry.extract("#{@local_results_dir}/#{entry.name}")
        end
      end
    rescue StandardError => e
      @ppg_job.update(status: 'failed')
      `#{Dir.home}/server_jobs/send_telegram.sh 'PPG#{job_id} #{e.message}'`
    end
  end

  def load_functionality_scores(job_id)
    csv_parent_dir = "#{@local_results_dir}/#{job_id}"
    loaded = @ppg_job.add_matches_from_csv(csv_parent_dir)

    # `rm -r #{@local_results_dir}/#{job_id}` if loaded
  end

  def send_mail(job_id)
    return unless @ppg_job.email_notification

    user = @ppg_job.user
    ServerJobMailer.with(user: user, job_title: @ppg_job.title, type: 'ppg', job_id: job_id).finished_job.deliver_now
  end

  def remove_remote_dir(results_path)
    # Net::SFTP.start(Rails.application.credentials[:xylocalyx_ip], 'lara', keys: ['/home/deploy/.ssh/xylocalyx']) do |sftp|
    Net::SSH.start(Rails.application.credentials[:xylocalyx_ip], 'lara', keys: ['/home/warpp/.ssh/xylocalyx']) do |session|
      # Delete results from server
      session.exec!("rm -r #{results_path}")
    end
  end
end
