# frozen_string_literal: true

class PpgJobManager
  include Sidekiq::Worker

  PARAMETER_TO_FLAG = {
    maxintron: '-x',
    minintron: '-n',
    stringency_value: '-v',
    model: '-m',
    best_hits: '-b',
    out_identity: '-i',
    out_frame_shifts: '-r',
    out_missing_genes: '-g',
    out_sequences: '-e',
    out_annotation: '-o'
  }.freeze

  def perform(ppg_job_id)
    ppg_job = PpgJob.find(ppg_job_id)
    prepare_targets(ppg_job_id)
    start_pipeline(build_command(ppg_job), ppg_job_id)
  end

  def prepare_targets(ppg_job_id)
    ppg_run_dir = "#{Dir.home}/server_jobs/ppg_scorer/#{ppg_job_id}"
    target_dir = "#{ppg_run_dir}/targets"
    return if Dir.exist?(target_dir)

    `mkdir -p #{target_dir}`

    sleep 5 while Dir["#{ppg_run_dir}/unprocessed_targets/*"].empty?
    target_files = Dir["#{ppg_run_dir}/unprocessed_targets/*"]

    target_files[0..20].each do |target_file|
      Bio::FlatFile.open(Bio::FastaFormat, target_file).each do |entry|
        File.open("#{target_dir}/#{entry.definition.split(' ')[0]}.fa", 'w') do |f|
          f.puts entry.seq.to_fasta(entry.definition.gsub("\t", "\s"), 80)
        end
      end
    end

    `rm -r #{ppg_run_dir}/unprocessed_targets`
  end

  def build_command(ppg_job)
    ppg_run_dir = "/data/data2/lara/warpp_server_jobs/ppg_scorer/#{ppg_job.id}"
    cmd = "ruby /data/data2/lara/warpp_server_jobs/ppg_scorer/ppg_scorer.rb #{ppg_run_dir} -d #{ppg_job.id}"

    cmd += case ppg_job.stringency
           when ['relaxed']
             ' -s relaxed'
           when ['stringent']
             ' -s stringent'
           else
             ' -s both'
           end

    PARAMETER_TO_FLAG.each do |parameter, flag|
      input = ppg_job[parameter]
      next if input.nil? || input.to_s&.empty? || !input

      cmd += " #{flag} #{input}"
    end

    cmd
  end

  def start_pipeline(command, job_id)
    logger.info 'Running PPG scorer'
    Net::SSH.start(Rails.application.credentials[:xylocalyx_ip], 'lara', keys: ['/home/deploy/.ssh/xylocalyx']) do |session|
      ppg_job_dir = "/data/data2/lara/warpp_server_jobs/ppg_scorer/#{job_id}"

      # Create analysis directory
      session.exec!("mkdir #{ppg_job_dir}")

      # Upload analysis input files
      session.scp.upload! "#{Dir.home}/server_jobs/ppg_scorer/#{job_id}/targets",
                          ppg_job_dir,
                          { recursive: true }

      # Start analysis on server
      session.exec!("screen -dmS PPG#{job_id}")
      session.exec!("screen -S PPG#{job_id} -X stuff '#{command}^M'")
    end
  end
end
