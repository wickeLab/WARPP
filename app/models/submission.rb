# frozen_string_literal: true

class Submission < ApplicationRecord
  # MIXINS

  # CONSTANTS

  # ATTRIBUTES

  # MISCELLANEOUS
  enum status: {
    pending: 'pending',
    accepted: 'accepted',
    rejected: 'rejected'
  }, _suffix: :submissions

  # ASSOCIATIONS
  belongs_to :user
  belongs_to :taxon, optional: true

  # SCOPES

  # CALLBACKS
  before_create :set_archive_status

  # INSTANCE METHODS
  def user_name
    user.user_name
  end

  def species_name
    taxon ? taxon.scientific_name : 'none'
  end

  def accept_submission
    information_to_process = submitted_information.select { |_k, info| !info.empty? }
    species_name = submitted_information['species_name']

    case request_type
    when 'destroy'
      taxon.destroy
      return
    when 'create'
      new_taxon = Taxon.find_by scientific_name: species_name
      raise 'Sorry, but this species already exists.' if new_taxon

      genus_entry = Taxon.where(scientific_name: submitted_information['parent_genus'])
      new_taxon = Taxon.create(scientific_name: species_name, parent: genus_entry)

      update(taxon: new_taxon)
    else
      taxon.scientific_name = species_name

      %w[lifespan lifestyle habit].each do |type|
        next unless information_to_process[type]

        taxon.lifetraits.where(type: type.capitalize).destroy_all
      end
    end

    # LIFE TRAITS
    %w[lifespan lifestyle habit chromosome_number genome_size].each do |type|
      next unless information_to_process[type]

      val = information_to_process[type]['value']
      references = information_to_process[type]['references']

      life_trait = Lifetrait.create(taxon: taxon, information: val, type: "#{type.gsub('_', ' ').capitalize.gsub(' ', '')}")

      unless life_trait.persisted?
        raise 'Submitted information could not be saved.'
      end

      life_trait.add_references(references)

      if life_trait.publications.empty? && !references.empty? && references != ['personal observation']
        raise 'References did not pass doi resolving.'
      end
    end

    # PR ADDITIONS
    %w[hosts_to_add parasites_to_add].each do |relation|
      next unless information_to_process[relation]

      information_to_process[relation].each do |pr_species_name, references|
        pr_taxon = Taxon.where(scientific_name: pr_species_name).first_or_create

        relationship_entry = if relation == 'hosts_to_add'
                               ParasiticRelationship.where(parasite: taxon, host: pr_taxon).first_or_create
                             else
                               ParasiticRelationship.where(parasite: pr_taxon, host: taxon).first_or_create
                             end

        references.each do |reference|
          next if reference == 'personal observation'

          publication = Publication.where(doi: reference).first_or_create
          if publication.persisted?
            relationship_entry.publications << publication
          end
        end

        if relationship_entry.publications.empty? && !references.empty? && references != ['personal observation']
          raise 'References did not pass doi resolving.'
        end
      end
    end

    # PR DELETIONS
    %w[hosts_to_delete parasites_to_delete].each do |relation|
      next unless information_to_process[relation]

      information_to_process[relation].each do |pr_species_name|
        pr_entry = Taxon.find_by scientific_name: pr_species_name

        if relation == 'hosts_to_delete'
          taxon.hosts.delete(pr_entry)
        else
          taxon.parasites.delete(pr_entry)
        end
      end
    end

    taxon.save
    update(status: 'accepted')
  end

  def reject_submission
    update(status: 'rejected')
  end

  # CLASS METHODS
  def self.transfer_json_to_jsonb
    Submission.all.each do |submission|
      submission.submitted_information = submission.submitted_info
      submission.submitted_info = {}
      submission.save
    end
  end

  # PRIVATE METHODS
  private

  def set_archive_status
    self.status ||= 'pending'
  end
end
