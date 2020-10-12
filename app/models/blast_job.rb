# frozen_string_literal: true

class BlastJob < ApplicationRecord
  # MIXINS

  # CONSTANTS
  DEFAULT_WORD_SIZE = 1
  DEFAULT_MAX_TARGET_SEQS = 1
  DEFAULT_EVALUE = '1e-10'

  # ATTRIBUTES
  has_one_attached :result_zip

  # MISCELLANEOUS
  enum status: {
    pending: 'pending',
    running: 'running',
    finished: 'finished',
    failed: 'failed'
  }, _suffix: :run

  # ASSOCIATIONS
  has_one :server_job, as: :job
  has_one :user, through: :server_job

  # VALIDATIONS
  validate :correct_result_mime_type

  # SCOPES

  # CALLBACKS
  after_commit :manage_job

  # INSTANCE METHODS
  def start_job
    BlastJobManagerWorker.perform_async(id)
    update(status: 'running')
  end

  # CLASS METHODS

  # PRIVATE METHODS
  private

  def correct_result_mime_type
    if !result_zip.attached? || result_zip.content_type.in?(%w[application/zip])
      return
    end

    errors.add(:result_zip, 'Must be a ZIP file')
  end

  def manage_job
    puts 'Checking for already running jobs.'
    running_jobs = BlastJob.where(status: 'running').length
    if pending_run? && running_jobs.zero?
      start_job
    elsif finished_run?
      puts 'Searching for next job to start.'
      next_job = BlastJob.where(status: 'pending').order(:created_at).first
      next_job&.start_job
    end
  end
end
