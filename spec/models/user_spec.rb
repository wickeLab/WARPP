require 'rails_helper'

RSpec.describe User, type: :model do
  context 'reference' do
    it 'lists_ppg_job' do
      ppg_job = PlastidPseudogeneScorer.create(name: 'job1')
      user = User.create(user_name: 'mr_smith')

      user.xylocalyx_jobs << ppg_job

      expect(user.xylocalyx_jobs).to include(ppg_job)
    end
  end
end
