# frozen_string_literal: true

class PpgJobsController < ApplicationController
  http_basic_authenticate_with name: Rails.application.credentials[:warpp_api][:user_name], password: Rails.application.credentials[:warpp_api][:password], only: %i[import]
  skip_before_action :verify_authenticity_token, only: %i[import]

  def stringent_datatable
    render json: PpgMatchStringentDatatable.new(params, { view_context: view_context, ppg_job: params[:ppg_job] })
  end

  def relaxed_datatable
    render json: PpgMatchRelaxedDatatable.new(params, { view_context: view_context, ppg_job: params[:ppg_job] })
  end

  def datatable
    render json: PpgMatchesDatatable.new(params, { view_context: view_context,
                                                   ppg_job: params[:ppg_job],
                                                   mode: params[:mode] })
  end

  def show
    @ppg_job = PpgJob.find(params[:id])
    authorize! :read, @ppg_job.server_job

    @user_targets = @ppg_job.ppg_matches.pluck(:target).uniq.sort.map { |target| target.gsub('.', '_') }
    gon.user_targets = @user_targets
  end

  def new
    redirect_to home_index_path unless user_signed_in?

    @ppg_job = PpgJob.new
  end

  def background; end

  def reference_data
    redirect_to home_index_path unless user_signed_in?

    @reference_targets = PpgMatch.reference_data.pluck(:target).uniq.sort.map { |target| target.gsub('.', '_') }
    gon.reference_targets = @reference_targets
  end

  def create
    submitted_information = params['ppg_job']
    submitted_information['stringency'] = if submitted_information['stringency'] == ['']
                                            ['stringent']
                                          else
                                            submitted_information['stringency'] - ['']
                                          end
    target_fastas = submitted_information.delete('target_fastas')

    @ppg_job = PpgJob.new(ppg_job_params)
    @ppg_job.user = current_user
    @ppg_job.save

    ppg_run_dir = "#{Dir.home}/server_jobs/ppg_scorer/#{@ppg_job.id}/unprocessed_targets"
    `mkdir -p #{ppg_run_dir}`

    unless params['seqs'].strip.empty?
      File.open("#{ppg_run_dir}/#{@ppg_job.id}.fa", 'w') do |f|
        f.puts params['seqs'].gsub('\r', '')
      end
    end

    target_fastas&.each do |target_fasta|
      File.open("#{ppg_run_dir}/#{target_fasta.original_filename}", 'w') do |f|
        f.write(target_fasta.read)
      end
    end

    redirect_to @ppg_job, success: 'Your job has been submitted.'
  end

  def import
    render plain: "Results for run with id #{params[:id]} will be imported in the background.\n"

    PpgJobImporterWorker.perform_async(params[:id], params[:result_path])
  end

  def download_result_zip
    ppg_job = PpgJob.find(params[:id])
    result_zip = ppg_job.result_zip
    file_path = ActiveStorage::Blob.service.path_for(result_zip.key)
    filename = if ppg_job.title.empty?
                 ppg_job.id.to_s
               else
                 ppg_job.title
               end
    send_file(file_path, filename: "PPGScorer#{filename.gsub(' ', '_')}.zip", disposition: 'attachment', type: "application/zip")
  end

  private

  def ppg_job_params
    params.require(:ppg_job).permit(:maxintron, :minintron, :stringency_value,
                                    :best_hits, :out_identity, :out_frame_shifts,
                                    :out_missing_genes, :out_sequences, :out_annotation,
                                    :email_notification, :title, stringency: [])
  end
end
