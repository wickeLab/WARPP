class ServerJobMailer < ApplicationMailer
  default from: 'no-reply@parasiticplants.app'

  def finished_job
    @user = params[:user]
    @url = case params[:type]
           when 'ppg'
             "https://parasiticplants.app/ppg_jobs/#{params[:job_id]}"
           else
             "https://parasiticplants.app/blast_jobs/#{params[:job_id]}"
           end
    @job_title = params[:job_title]
    mail(to: @user.email, subject: "Your job #{@job_title} has finished")
  end
end
