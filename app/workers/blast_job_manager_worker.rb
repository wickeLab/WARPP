class BlastJobManagerWorker
  include Sidekiq::Worker

  PARAMETER_TO_FLAG = {
    evalue: '-e',
    word_size: '-w',
    max_target_seqs: '-m',
    species: '-s'
  }.freeze

  def perform(blast_job_id)
    blast_job = BlastJob.find(blast_job_id)
    start_pipeline(build_command(blast_job), blast_job_id)
  end

  def build_command(blast_job)
    blast_run_dir = "/data/data2/lara/warpp_server_jobs/blast/#{blast_job.id}"
    cmd = "ruby /data/data2/lara/warpp_server_jobs/blast/run_blast.rb #{blast_run_dir} -d #{blast_job.id}"

    PARAMETER_TO_FLAG.each do |parameter, flag|
      input = blast_job[parameter]
      next if input.nil? || input.to_s&.empty? || !input

      cmd += " #{flag} #{input.gsub(' ', '_')}"
    end

    cmd
  end

  def start_pipeline(command, job_id)
    logger.info 'Running Blast'
    Net::SSH.start(Rails.application.credentials[:xylocalyx_ip], 'lara', keys: ['/home/deploy/.ssh/xylocalyx']) do |session|
      blast_job_dir = "/data/data2/lara/warpp_server_jobs/blast/#{job_id}"

      # Create analysis directory
      session.exec!("mkdir #{blast_job_dir}")

      # Upload analysis input files
      session.scp.upload! "#{Dir.home}/server_jobs/blast/#{job_id}/queries",
                          blast_job_dir,
                          { recursive: true }

      # Start analysis on server
      session.exec!("screen -dmS Blast#{job_id}")
      session.exec!("screen -S Blast#{job_id} -X stuff '#{command}^M'")
    end
  end
end
