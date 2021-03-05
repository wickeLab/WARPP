class BlastJobManagerWorker
  include Sidekiq::Worker
  include Exceptions

  PARAMETER_TO_FLAG = {
    evalue: '-e',
    word_size: '-w',
    max_target_seqs: '-m',
    species: '-s'
  }.freeze

  def perform(blast_job_id)
    @blast_job = BlastJob.find(blast_job_id)
    check_query_number(blast_job_id)
    start_pipeline(build_command, blast_job_id)
  end

  def check_query_number(job_id)
    dir_size = `du -hk #{Dir.home}/server_jobs/blast/#{job_id}/queries`.split("\t")[0].to_i
    return if dir_size <= 10_000

    query_files = Dir["#{Dir.home}/server_jobs/blast/#{job_id}/queries/*"]

    if query_files.length == 1
      @blast_job.report_failure
      raise Exceptions::FileSizeError, 'BLAST query file size was larger than 10MB and could not be reduced.'
    end

    processed_query_dir = "#{Dir.home}/server_jobs/blast/#{job_id}/processed_queries"
    `mkdir #{processed_query_dir}`

    i = 0
    query_files.each do |query_file|
      Bio::FlatFile.open(Bio::FastaFormat, query_file).each do |entry|
        File.open("#{processed_query_dir}/#{i}.fa", 'w') do |f|
          f.puts entry.seq.to_fasta(entry.definition, 80)
        end

        i += 1
        dir_size = `du -hk #{processed_query_dir}`.split("\t")[0].to_i
        next unless dir_size >= 10_000

        `rm #{processed_query_dir}/#{i - 1}.fa`
        break
      end

      next unless dir_size >= 10_000

      break
    end

    `rm #{Dir.home}/server_jobs/blast/#{job_id}/queries/*`
    `cat #{processed_query_dir}/* > #{Dir.home}/server_jobs/blast/#{job_id}/queries/#{job_id}.fa`
    # `rm -r #{processed_query_dir}`
  end

  def build_command
    blast_run_dir = "/data/data2/lara/warpp_server_jobs/blast/#{@blast_job.id}"
    cmd = "ruby /data/data2/lara/warpp_server_jobs/blast/run_blast.rb #{blast_run_dir} -d #{@blast_job.id}"

    PARAMETER_TO_FLAG.each do |parameter, flag|
      input = @blast_job[parameter]
      next if input.nil? || input.to_s&.empty? || !input

      cmd += " #{flag} #{input.to_s.gsub(' ', '_')}"
    end

    cmd
  end

  def start_pipeline(command, job_id)
    logger.info 'Running Blast'
    Net::SSH.start(Rails.application.credentials[:xylocalyx_ip], 'lara', keys: ['/home/warpp/.ssh/xylocalyx']) do |session|
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
