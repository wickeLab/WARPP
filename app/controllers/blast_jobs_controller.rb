# frozen_string_literal: true

class BlastJobsController < ApplicationController
  http_basic_authenticate_with name: Rails.application.credentials[:warpp_api][:user_name], password: Rails.application.credentials[:warpp_api][:password], only: %i[import]
  skip_before_action :verify_authenticity_token, only: %i[import]

  def show
    @blast_job = BlastJob.find(params[:id])
  end

  def background; end

  def new
    @blast_job = BlastJob.new
  end

  def create
    submitted_information = params['blast_job']
    query_fastas = submitted_information.delete('query_fastas')

    @blast_job = BlastJob.new(blast_job_params)
    @blast_job.user = current_user
    @blast_job.save

    blast_job_dir = "#{Dir.home}/server_jobs/blast/#{@blast_job.id}/queries"
    `mkdir -p #{blast_job_dir} 2> /dev/null`

    unless params['seqs'].strip.empty?
      File.open("#{blast_job_dir}/#{@blast_job.id}.fa", 'w') do |f|
        f.puts params['seqs'].gsub('\r', '')
      end
    end

    query_fastas&.each do |query_fasta|
      File.open("#{blast_job_dir}/#{query_fasta.original_filename}", 'w') do |f|
        f.write(query_fasta.read)
      end
    end

    redirect_to @blast_job, success: 'Your job has been submitted.'
  end

  def import
    render plain: "Results for run with id #{params[:id]} will be imported in the background.\n"

    BlastJobImporterWorker.perform_async(params[:id], params[:result_path])
  end

  def download_result_zip
    blast_job = BlastJob.find(params[:id])
    result_zip = blast_job.result_zip
    file_path = ActiveStorage::Blob.service.path_for(result_zip.key)
    filename = if blast_job.title.empty?
                 blast_job.id
               else
                 blast_job.title
               end
    send_file(file_path, filename: "BLAST#{filename.gsub(' ', '_')}.zip", disposition: 'attachment', type: "application/zip")
  end

  private

  def blast_job_params
    params.require(:blast_job).permit(:email_notification, :title, :evalue,
                                      :word_size, :max_target_seqs, :species)
  end
end
