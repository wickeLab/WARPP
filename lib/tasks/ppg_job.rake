# frozen_string_literal: true

namespace :ppg_job do
  desc 'Load reference functionality scores from tsv'
  task load_reference_data: :environment do |_t|
    reference_data_path = Rails.root.join('data', 'ppg_reference_data')
    reference_data_so_far = PpgMatch.reference_data

    %w[relaxed stringent].each do |stringency|
      Dir["#{reference_data_path}/#{stringency}/*"].each do |ppg_ref_tsv|
        CSV.open(ppg_ref_tsv, col_sep: "\t", headers: true).each do |row|
          query = row.delete('functionality_score')[1]
          query_entry = PpgQuery.where(query_name: query, functional_assignment: 'unknown').first_or_create
          row.each do |target, match|
            ppg_match = reference_data_so_far.find_by target: target, ppg_query: query_entry, stringency: stringency
            if ppg_match
              ppg_match.update(functionality_score: match)
            else
              PpgMatch.create(target: target, ppg_query: query_entry, functionality_score: match, stringency: stringency)
            end
          end
        end
      end
    end
  end

  desc 'Load functional assignments of queries'
  task load_functional_assignments: :environment do |_t|
    functional_assignments_csv = Rails.root.join('data', 'ppg_functional_assignments')

    CSV.foreach("#{functional_assignments_csv}/plastGenes_FuncAssignments.csv", col_sep: "\t") do |row|
      query = row[0]
      assignment = row[1]
      query_entry = PpgQuery.where('query_name ~* ?', query).first
      query_entry.update(functional_assignment: assignment)
    end
  end
end
