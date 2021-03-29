# frozen_string_literal: true

require 'rails_helper'
require 'rake'
Rake.application.rake_require 'tasks/set_missions_to_regulated'

RSpec.describe 'mission:set_missions_to_regulated', type: :feature do
  before do
    allow(DateTime).to receive(:current).and_return DateTime.new(2020, 12, 10, 10)
  end

  let(:mission) { create :mission, name: 'permanence clac', start_date: DateTime.current + 2.days }

  it "set future missions with name 'permanence clac' and genre 'standard' to regulated" do
    mission # create mission

    Rake::Task['mission:set_missions_to_regulated'].execute

    expect(mission.reload.genre).to eq 'regulated'
  end

  context "when an enrollment of the mission is not matching the mission 's timeslots" do
    let(:create_enrollment) do
      create :enrollment,
             start_time: mission.start_date + 1.hour,
             end_time: mission.due_date + 2.5.hours,
             mission_id: mission.id
    end

    it "doesn't update the mission" do
      create_enrollment

      Rake::Task['mission:set_missions_to_regulated'].execute

      expect(mission.reload.genre).not_to eq 'regulated'
    end
  end

  context 'when an enrollment of the mission have not a duration which is a multiple of 90 minutes' do
    let(:create_enrollment) do
      create :enrollment,
             start_time: mission.start_date + 1.hour,
             end_time: mission.due_date,
             mission_id: mission.id
    end

    it "doesn't update the mission" do
      create_enrollment

      Rake::Task['mission:set_missions_to_regulated'].execute

      expect(mission.reload.genre).not_to eq 'regulated'
    end
  end
end
