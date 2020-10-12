Rails.application.routes.draw do
  concern :with_datatable do
    post 'datatable', on: :collection
  end
  devise_for :users

  get 'home/index'

  post 'filter_tree', to: 'taxon#get_filtered_tree', as: 'get_filtered_tree'
  post 'search_species', to: 'taxon#search', as: 'search_species'
  get 'taxa/search/:keyword', to: 'taxon#search', as: 'search'
  get 'taxonomy/phylogenetic_tree', to: 'taxon#getTree', as: 'phylogenetic_tree'
  get 'show_children/:scientific_name', to: 'taxon#show_children', as: 'show_children_taxa'
  get 'show_alternatives/:scientific_name', to: 'taxon#show_alternatives', as: 'show_alternatives_taxa'
  get 'taxonomy_browser/:family', to: 'taxon#index', as: 'taxonomy_browser'
  get 'taxonomy_browser', to: 'taxon#browser_index', as: 'taxonomy_browser_index'
  get 'taxa/search', to: 'taxon#multifamily_search_list', as: 'list_multifamily_search_results'
  get 'taxa/:id', to: 'taxon#show', as: 'taxon'
  resources :taxon, only: %i[index new edit]

  get 'submissions/:id/accept', to: 'submissions#accept', as: 'accept_submission'
  get 'submissions/:id/reject', to: 'submissions#reject', as: 'reject_submission'
  resources :submissions, concerns: [:with_datatable]

  resources :publications, concerns: [:with_datatable]

  get 'genome_browser/jbrowse', to: 'genome_browsers#jbrowse', as: 'jbrowse'
  resources :genome_browsers, only: %i[index]

  resources :trees

  get 'download_ortho_tree/:id', to: 'orthogroups#download_newick', as: 'download_ortho_newick'
  get 'download_ortho_fasta/:id', to: 'orthogroups#download_fasta', as: 'download_ortho_fasta'
  resources :orthogroups, concerns: [:with_datatable]

  resources :server_jobs, only: %i[index], concerns: [:with_datatable]

  get 'blast_jobs/background', to: 'blast_jobs#background', as: 'blast_jobs_background'
  get 'blast_jobs/:id/download_result_zip', to: 'blast_jobs#download_result_zip', as: 'download_blast_result'
  post 'blast_jobs/:id/import', to: 'blast_jobs#import', as: 'import_blast_results'
  resources :blast_jobs, except: %i[update destroy index]

  get 'ppg_jobs/reference_scores', to: 'ppg_jobs#reference_data', as: 'ppg_jobs_references'
  get 'ppg_jobs/background', to: 'ppg_jobs#background', as: 'ppg_jobs_background'
  get 'ppg_jobs/:id/download_result_zip', to: 'ppg_jobs#download_result_zip', as: 'download_ppg_result'
  post 'ppg_jobs/:id/import', to: 'ppg_jobs#import', as: 'import_ppg_results'
  post 'ppg_jobs/relaxed_datatable', to: 'ppg_jobs#relaxed_datatable', as: 'relaxed_datatable_ppg_jobs'
  post 'ppg_jobs/stringent_datatable', to: 'ppg_jobs#stringent_datatable', as: 'stringent_datatable_ppg_jobs'
  resources :ppg_jobs, except: %i[update destroy index], concerns: [:with_datatable]

  post 'ppg_queries/datatable', to: 'ppg_queries#datatable', as: 'datatable_ppg_queries'

  get 'warpp', to: 'about#warpp', as: 'warpp'
  get 'parasitic_plant_biology', to: 'about#parasitic_plant_biology', as: 'parasitic_plant_biology'
  get 'analytics', to: 'about#analytics', as: 'analytics'

  get 'legal_disclosure', to: 'impressum#legal_disclosure', as: 'legal_disclosure'
  get 'privacy_policy', to: 'impressum#privacy_policy', as: 'privacy_policy'

  root 'home#index', as: 'root'

  devise_scope :user do
    # authenticated :user do
    #   root 'about#warpp', as: :authenticated_root
    # end

    # unauthenticated do
    #   root 'devise/sessions#new', as: :unauthenticated_root
    # end
  end
end
