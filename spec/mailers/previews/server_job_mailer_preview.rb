# Preview all emails at http://localhost:3000/rails/mailers/server_job_mailer
class ServerJobMailerPreview < ActionMailer::Preview
  def finished_job
    ServerJobMailer.with(user: User.first).finished_job
  end
end
