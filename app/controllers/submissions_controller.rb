class SubmissionsController < ApplicationController
  def create
    species_information = JSON.parse(params['informationOverview'])

    species = if species_information['species']
                Taxon.find(species_information['species'])
              end

    user = User.find(species_information['user'])
    request_type = species_information['request_to']
    submitted_information = species_information['submittedInformation']

    submission = Submission.create(taxon: species, user: user, request_type: request_type, submitted_information: submitted_information)

    if user_signed_in? && current_user.user_name == 'Susann'
      submission.accept_submission
    end

    if species
      redirect_to taxon_path(id: species.id), success: 'Your information was submitted. Thanks for contributing!'
    else
      redirect_to root_path, success: 'Your information was submitted. Thanks for contributing!'
    end
  end

  def accept
    begin
      Submission.find(params[:id]).accept_submission
      redirect_to submissions_path
    rescue RuntimeError => e
      redirect_to submissions_path, flash: { error: e.message }
    end
  end

  def reject
    Submission.find(params[:id]).reject_submission
    redirect_to submission_index_path
  end

  def index
    unless user_signed_in? && (current_user.admin? || current_user.group_member?)
      redirect_to unauthenticated_root_path
    end
  end

  def datatable
    render json: SubmissionsDatatable.new(params, {view_context: view_context, user_role: current_user.role })
  end

  def show
    unless user_signed_in? && (current_user.admin? || current_user.group_member?)
      redirect_to unauthenticated_root_path
    end
    submission = Submission.find(params[:id])
    @submission_id = params[:id]
    submitted_information = submission.submitted_information

    @hosts_to_add = submitted_information['hosts_to_add']
    @hosts_to_delete = submitted_information['hosts_to_delete']
    @parasites_to_add = submitted_information['parasites_to_add']
    @parasites_to_delete = submitted_information['parasites_to_delete']

    if submission.taxon
      taxon = submission.taxon
      @old_name = taxon.scientific_name ? taxon.scientific_name : 'unknown'
      @old_lifestyle = taxon.lifestyle ? taxon.lifestyle : 'unknown'
      @old_lifespan = taxon.lifespan ? taxon.lifespan : 'unknown'
      @old_habit = taxon.habit ? taxon.habit : 'unknown'
      @old_chromosome_number = taxon.chromosome_number ? taxon.chromosome_number : 'unknown'
      @old_genome_size = taxon.genome_size ? taxon.genome_size : 'unknown'
    else
      @old_name = nil
    end

    if submitted_information['parent_genus']
      @lineage = [submitted_information['parent_genus'], submitted_information['parent_family']]
    else
      @lineage = false
    end

    @new_name = if submitted_information['species_name'].empty?
                  false
                else
                  submitted_information['species_name']
                end

    @lifestyle = if submitted_information['lifestyle'].empty?
                   false
                 else
                   submitted_information['lifestyle']
                 end

    @lifespan = if submitted_information['lifespan'].empty?
                  false
                else
                  submitted_information['lifespan']
                end

    if !submitted_information['habit'] || submitted_information['habit'].empty?
      @habit = false
    else
      @habit = submitted_information['habit']
    end

    if !submitted_information['chromosome_number'] || submitted_information['chromosome_number'].empty?
      @chromosome_number = false
    else
      @chromosome_number = submitted_information['chromosome_number']
    end

    if !submitted_information['genome_size'] || submitted_information['genome_size'].empty?
      @genome_size = false
    else
      @genome_size = submitted_information['genome_size']
    end

    @user_name = submission.user.user_name
  end
end
