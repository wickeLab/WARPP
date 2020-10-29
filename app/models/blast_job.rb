# frozen_string_literal: true

class BlastJob < ApplicationRecord
  # MIXINS

  # CONSTANTS
  DEFAULT_WORD_SIZE = 1
  DEFAULT_MAX_TARGET_SEQS = 1
  DEFAULT_EVALUE = '1e-10'
  AVAILABLE_SPECIES = ['Aeginetia indica', 'Alectra orobanchoides', 'Aphyllon californicum', 'Aphyllon epigalium',
                       'Aphyllon fasciculatum', 'Aphyllon purpureum', 'Aphyllon uniflorum', 'Aureolaria virginica',
                       'Balanophora laxiflora', 'Balanophora reflexa', 'Boulardia latisquama', 'Buchnera americana',
                       'Cassytha capillaris', 'Cassytha filiformis', 'Castilleja paramensis', 'Cistanche deserticola',
                       'Cistanche phelypaea', 'Cistanthe longiscapa', 'Conopholis americana', 'Cuscuta australis',
                       'Cuscuta campestris', 'Cuscuta exaltata', 'Cuscuta gronovii', 'Cuscuta obtusiflora',
                       'Cuscuta pentagona', 'Cuscuta reflexa', 'Cynomorium coccineum', 'Cytinus hypocistis',
                       'Dendrotrophe varians', 'Epifagus virginiana', 'Euphrasia minima', 'Euphrasia petiolaris',
                       'Hydnora visseri', 'Kopsiopsis hookeri', 'Lathraea clandestina', 'Lathraea squamaria',
                       'Lindenbergia philippensis', 'Macrosolen cochinchinensis', 'Melampyrum pratense',
                       'Neobartsia inaequalis', 'Orobanche austrohispanica', 'Orobanche cernua', 'Orobanche crenata',
                       'Orobanche cumana', 'Orobanche densiflora', 'Orobanche gracilis', 'Orobanche minor',
                       'Orobanche pancicii', 'Orobanche rapumgenistae', 'Pedicularis cheilanthifolia',
                       'Pedicularis hallaisanensis', 'Pedicularis ishidoyana', 'Phelipanche aegyptiaca',
                       'Phelipanche lavandulacea', 'Phelipanche purpurea', 'Phelipanche ramosa', 'Pholisma arenarium',
                       'PhtheirospermumJaponicum', 'Pilostyles aethiopica', 'Pilostyles hamiltonii',
                       'Rehmannia glutinosa', 'Rhinanthus serotinus', 'Schoepfia jasminodora', 'Schwalbea americana',
                       'Scurrula parasitica', 'Striga asiatica', 'Striga aspera', 'Striga forbesii',
                       'Striga gesnerioides', 'Striga hermonthica', 'Taxillus chinensis', 'Taxillus sutchuenensis',
                       'Tozzia alpina', 'Triphysaria versicolor', 'Viscum album', 'Viscum coloratum',
                       'Viscum crassulae', 'Viscum minimum', 'Ximenia americana'].freeze

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

  def report_failure
    update(status: 'failed')
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
