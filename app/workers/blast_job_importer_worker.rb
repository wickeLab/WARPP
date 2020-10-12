# frozen_string_literal: true

class BlastJobImporterWorker
  include Sidekiq::Worker

  def perform(job_id, results_path)
    @blast_job = BlastJob.find(job_id)
    @result_zip_path = "#{results_path}/#{job_id}.zip"
    @local_results_dir = "#{Dir.home}/server_jobs/blast/#{job_id}"
    @local_zip_path = "#{@local_results_dir}/#{job_id}_results.zip"

    import_results(job_id)
    @blast_job.result_zip.attach(io: File.open(@local_zip_path), filename: "#{job_id}.zip")

    @blast_job.update(status: 'finished')
    send_mail
    remove_remote_dir(results_path)
  end

  def import_results(job_id)
    Net::SSH.start(Rails.application.credentials[:xylocalyx_ip], 'lara', keys: ['/home/deploy/.ssh/xylocalyx']) do |session|
      # Download result file
      session.scp.download!(@result_zip_path, @local_zip_path)
    rescue StandardError => e
      @blast_job.update(status: 'failed')
      `#{Dir.home}/server_jobs/send_telegram.sh 'Blast#{job_id} #{e.message}'`
    end
  end

  def send_mail
    return unless @blast_job.email_notification

    user = @blast_job.user
    ServerJobMailer.with(user: user, job_title: @blast_job.title, type: 'blast', job_id: job_id).finished_job.deliver_now
  end

  def remove_remote_dir(results_path)
    # Net::SFTP.start(Rails.application.credentials[:xylocalyx_ip], 'lara', keys: ['/home/deploy/.ssh/xylocalyx']) do |sftp|
    Net::SSH.start(Rails.application.credentials[:xylocalyx_ip], 'lara', keys: ['/home/deploy/.ssh/xylocalyx']) do |session|
      # Delete results from server
      session.exec!("rm -r #{results_path}")
    end
  end
end
