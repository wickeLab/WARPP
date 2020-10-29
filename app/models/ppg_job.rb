# frozen_string_literal: true

class PpgJob < ApplicationRecord
  # MIXINS

  # CONSTANTS
  DEFAULT_MAXINTRON = 6000
  DEFAULT_MININTRON = 200
  DEFAULT_STRINGENCY_VALUE = 0.02
  DEFAULT_BEST_HITS = 1

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

  has_one :ppg_input

  has_many :ppg_matches, dependent: :destroy
  has_many :ppg_queries, through: :ppg_matches

  # VALIDATIONS
  validate :correct_result_mime_type

  # SCOPES

  # CALLBACKS
  after_commit :manage_job
  before_destroy :destroy_job

  # INSTANCE METHODS
  def start_job
    PpgJobManagerWorker.perform_async(id)
    update(status: 'running')
  end

  def add_matches_from_csv(csv_parent_dir)
    stringency.each do |stringency|
      csv_file = "#{csv_parent_dir}/tables_#{stringency}/functionality_scores.txt"
      CSV.foreach(csv_file, col_sep: "\t", headers: true) do |row|
        query = row.delete('functionality_score')[1]
        row.each do |target, match|
          query_entry = PpgQuery.find_by query_name: query
          PpgMatch.create(target: target,
                          ppg_query: query_entry,
                          ppg_job: self,
                          functionality_score: match,
                          stringency: stringency)
        end
      end
    end

    true
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
    running_jobs = PpgJob.where(status: 'running').length
    if pending_run? && running_jobs.zero?
      start_job
    elsif finished_run?
      puts 'Searching for next job to start.'
      next_job = PpgJob.where(status: 'pending').order(:created_at).first
      next_job&.start_job
    end
  end

  def destroy_job
    ppg_matches.destroy_all
  end
end
