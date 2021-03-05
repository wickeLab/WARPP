# frozen_string_literal: true

class BlastJob < ApplicationRecord
  # MIXINS

  # CONSTANTS
  DEFAULT_WORD_SIZE = 1
  DEFAULT_MAX_TARGET_SEQS = 1
  DEFAULT_EVALUE = '1e-10'
  AVAILABLE_SPECIES = {
    plastid_only: [
      'Aphyllon epigalium', 'Aphyllon fasciculatum', 'Aphyllon purpureum',
      'Aphyllon uniflorum', 'Aureolaria virginica', 'Balanophora laxiflora',
      'Balanophora reflexa', 'Boulardia latisquama', 'Buchnera americana',
      'Cassytha capillaris', 'Cassytha filiformis', 'Castilleja paramensis',
      'Cistanche deserticola', 'Cistanche phelypaea', 'Cistanthe longiscapa',
      'Cuscuta exaltata', 'Cuscuta gronovii', 'Cuscuta obtusiflora',
      'Cuscuta pentagona', 'Cuscuta reflexa', 'Cynomorium coccineum',
      'Cytinus hypocistis', 'Dendrotrophe varians', 'Epifagus virginiana',
      'Hydnora visseri', 'Lathraea squamaria', 'Macrosolen cochinchinensis',
      'Neobartsia inaequalis', 'Orobanche austrohispanica', 'Orobanche densiflora',
      'Orobanche pancicii', 'Orobanche rapumgenistae', 'Pedicularis cheilanthifolia',
      'Pedicularis hallaisanensis', 'Pedicularis ishidoyana', 'Phelipanche lavandulacea',
      'Phelipanche purpurea',  'Pholisma arenarium', 'Pilostyles aethiopica',
      'Pilostyles hamiltonii', 'Schoepfia jasminodora', 'Scurrula parasitica',
      'Striga aspera', 'Striga forbesii', 'Taxillus chinensis',
      'Taxillus sutchuenensis', 'Viscum album', 'Viscum coloratum',
      'Viscum crassulae', 'Viscum minimum', 'Ximenia americana'
    ],
    others: [
      'Aeginetia indica', 'Alectra orobanchoides', 'Aphyllon californicum',
      'Conopholis americana', 'Cuscuta australis', 'Cuscuta campestris',
      'Euphrasia minima', 'Euphrasia petiolaris', 'Kopsiopsis hookeri',
      'Lathraea clandestina', 'Lindenbergia philippensis', 'Melampyrum pratense',
      'Orobanche cernua', 'Orobanche crenata', 'Orobanche cumana',
      'Orobanche gracilis', 'Orobanche minor', 'Phelipanche aegyptiaca',
      'Phelipanche ramosa', 'Phtheirospermum japonicum', 'Rehmannia glutinosa',
      'Rhinanthus serotinus', 'Schwalbea americana', 'Striga asiatica',
      'Striga gesnerioides', 'Striga hermonthica', 'Tozzia alpina',
      'Triphysaria versicolor'
    ]
  }.freeze

  # ATTRIBUTES
  has_one_attached :result_zip
  attribute :temporary_folder, :text

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
  validate :correct_result_mime_type, if: :finished_run?
  validate :are_valid_queries?, on: :create
  validates_presence_of :user

  # SCOPES

  # CALLBACKS
  after_validation :remove_folder, on: :create, if: proc { |blast_job| blast_job.errors.any? }
  after_create :move_folder
  # NOTE: after_commit and after_rollback methods are fired in reverse order
  # after_commit :manage_job

  # INSTANCE METHODS
  def start_job
    BlastJobManagerWorker.perform_async(id)
    update(status: 'running')
  end

  def report_failure(error_message)
    update(status: 'failed', error_message: error_message)
  end

  def save_queries(fastas, text_input)
    Retryable.retryable(tries: Float::INFINITY, on: IOError) do
      random_job_descr = (0..21).map { |_i| [*'a'..'z', *0..9].sample }.join('')
      self.temporary_folder = "#{Dir.home}/server_jobs/blast/#{random_job_descr}"
      raise IOError if Dir.exist?(temporary_folder)

      queries_dir = "#{temporary_folder}/queries"
      `mkdir -p #{queries_dir} 2> /dev/null`

      unless text_input.strip.empty?
        File.open("#{queries_dir}/#{random_job_descr}.fa", 'w') do |f|
          f.puts text_input.gsub('\r', '')
        end
      end

      fastas&.each do |query_fasta|
        File.open("#{queries_dir}/#{query_fasta.original_filename}", 'a') do |f|
          f.write(query_fasta.read)
        end
      end
    end
  end

  # CLASS METHODS

  # PRIVATE METHODS
  private

  # VALIDATIONS
  def correct_result_mime_type
    return if !result_zip.attached? || result_zip.content_type.in?(%w[application/zip])

    errors.add(:result_zip, 'Must be a ZIP file')
  end

  def are_valid_queries?
    query_fas = Dir["#{temporary_folder}/queries/*"]
    if query_fas.empty?
      errors.add(:base, 'Please provide at least one query sequence.')
      return
    end

    query_fas.each do |query_fa|
      # fasta?
      unless Bio::FlatFile.autodetect_file(query_fa) == Bio::FastaFormat
        errors.add(:base, 'Your queries are not in FASTA format.')
        return
      end

      # nucleotide_queries?
      Bio::FlatFile.foreach(Bio::FastaFormat, query_fa) do |query|
        unless Bio::Sequence.guess(query.seq) == Bio::Sequence::NA
          errors.add(:base, 'Please make sure that your FASTAS contain only nucleotide queries.')
          return
        end
      end
    end
  end

  # CALLBACKS
  def remove_folder
    `rm -r #{temporary_folder}`
  end

  def move_folder
    blast_job_dir = "#{Dir.home}/server_jobs/blast/#{id}"
    `mv #{temporary_folder} #{blast_job_dir}`
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
