class PpgMatchesDatatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegators :@view, :array_to_ul

  def initialize(params, opts = {})
    @view = opts[:view_context]

    @ppg_job = PpgJob.find(opts[:ppg_job]) if opts[:ppg_job]

    @matches = case opts[:mode]
               when 'stringent'
                 if @ppg_job
                   @ppg_job.ppg_matches.stringent
                 else
                   PpgMatch.reference_data.stringent
                 end
               else # relaxed
                 if @ppg_job
                   @ppg_job.ppg_matches.relaxed
                 else
                   PpgMatch.reference_data.relaxed
                 end
               end

    @targets = @matches.pluck(:target).uniq.sort
    super
  end

  def view_columns
    targets = @targets.map do |target|
      [target.gsub('.', '_'), {}]
    end.to_h.symbolize_keys

    @view_columns ||= {
      query_name: { source: 'PpgQuery.query_name' },
      functional_assignment: { source: 'PpgQuery.functional_assignment' },
      median_functionality_score: { source: 'PpgQuery.median_functionality_score' }
    }.merge!(targets)
  end

  def data
    records.map do |record|
      median_functionality_score = record.median_functionality_score.round(2)

      return_value = []
      @targets.each do |target|
        match = @matches.find_by target: target, ppg_query: record
        return_value += if match&.functionality_score
                          match_functionality_score = match.functionality_score.round(2)
                          functionality_score_deviation = (match_functionality_score - median_functionality_score).round(2)
                          [[target.gsub('.', '_'), array_to_ul([match_functionality_score, "dev: #{functionality_score_deviation}"])]]
                        else
                          [[target.gsub('.', '_'), 'no match']]
                        end
      end

      return_value += [
        ['query_name', record.query_name[/[a-z]+/i]],
        ['functional_assignment', record.functional_assignment],
        ['median_functionality_score', median_functionality_score]
      ]

      return_value.to_h.symbolize_keys
    end
  end

  def get_raw_records
    PpgQuery.all.order(:query_name)
  end

end
