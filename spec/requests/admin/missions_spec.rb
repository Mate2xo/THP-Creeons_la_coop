# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'A Missions admin request', type: :request do
  let(:current_admin) { create :member, :super_admin }

  before do
    sign_in current_admin
    allow(DateTime).to receive(:current).and_return DateTime.new(2020, 12, 10, 10)
  end

  describe '#generate_schedule' do
    subject(:post_generate_schedule) { post generate_schedule_admin_missions_path(3) }

    context 'when all schedules asked has been already generated' do
      it 'notices that the schedule has already been generated' do
        create_history_of_generated_schedule_for_n_months(3)
        post_generate_schedule
        follow_redirect!

        expect(response.body).to include(I18n.t('admin.missions.generate_schedule.schedule_already_generated'))
      end
    end
  end

  describe 'POST' do
    subject(:post_mission) { post admin_missions_path, params: { mission: mission_params } }

    context 'when the :genre params is set to event' do
      let(:mission_params) { generate_attributes_for_mission genre: 'event', author_id: current_admin.id }

      it 'creates the mission with the genre set to event' do
        post_mission

        expect(Mission.last[:genre]).to eq 'event'
      end
    end

    context 'when the duration is negative' do
      let(:mission_params) do
        generate_attributes_for_mission start_date: DateTime.current, due_date: DateTime.current - 5.minutes
      end

      it 'sends an error message when due date is inferior to start_date' do
        post_mission

        expect(response.body).to include(I18n.t('activerecord.errors.models.mission.attributes.duration.minimum'))
      end
    end

    context 'when the duration is superior to ten hours' do
      let(:mission_params) do
        generate_attributes_for_mission start_date: DateTime.current, due_date: DateTime.current + 11.hours
      end

      it 'displays an error message' do
        post_mission

        expect(response.body).to include(I18n.t('activerecord.errors.models.mission.attributes.duration.maximum'))
      end
    end

    context 'when the mission is regulated and the duration is not a multiple of 1.5 hours' do
      let(:mission_params) do
        generate_attributes_for_mission({ genre: 'regulated',
                                          start_date: DateTime.current,
                                          due_date: DateTime.current + 1.hour })
      end

      it 'displays an error message' do
        post_mission

        expect(response.body).to include(I18n.t('activerecord.errors.models.mission.attributes.duration.multiple'))
      end
    end
  end

  describe 'PUT' do
    subject(:put_mission) { put admin_mission_path(mission.id), params: { mission: mission_params } }

    let(:mission) { create :mission, start_date: DateTime.current + 2.days }
    let(:mission_params) do
      generate_attributes_for_mission({ name: 'updated_mission',
                                        start_date: mission.start_date + 3.hours,
                                        due_date: mission.start_date + 6.hours })
    end

    let!(:expected_params) do
      { name: 'updated_mission', start_date: mission.start_date + 3.hours, due_date: mission.due_date + 3.hours }
    end

    before { allow(DateTime).to receive(:current).and_return DateTime.new(2020, 2, 3, 9) }

    it 'updates the mission' do
      put_mission

      expect(mission.reload.attributes).to include(expected_params.stringify_keys)
    end

    it 'confirms the updates' do
      put_mission
      follow_redirect!

      expect(response.body).to include(I18n.t('missions.update.confirm_update'))
    end

    context 'when the mission is :regulated and the params standard is passed' do
      let(:mission) { create :mission, start_date: DateTime.current + 2.days, genre: 'regulated' }

      let(:mission_params) do
        generate_attributes_for_mission({ name: 'updated_mission',
                                          start_date: mission.start_date,
                                          due_date: mission.due_date,
                                          genre: 'standard' })
      end

      it 'confirms the update' do
        put_mission
        follow_redirect!

        expect(response.body).to include(I18n.t('missions.update.confirm_update'))
      end
    end

    context 'when the duration is negative' do
      let(:mission_params) do
        generate_attributes_for_mission start_date: DateTime.current, due_date: DateTime.current - 5.minutes
      end

      it 'sends an error message when due date is inferior to start_date' do
        put_mission

        expect(response.body).to include(I18n.t('activerecord.errors.models.mission.attributes.duration.minimum'))
      end
    end

    context 'when the duration is superior to ten hours' do
      let(:mission_params) do
        generate_attributes_for_mission start_date: DateTime.current, due_date: DateTime.current + 11.hours
      end

      it 'displays an error message' do
        put_mission

        expect(response.body).to include(I18n.t('activerecord.errors.models.mission.attributes.duration.maximum'))
      end
    end

    context 'when the mission is regulated and the duration is not a multiple of 1.5 hours' do
      let(:mission_params) do
        generate_attributes_for_mission({ genre: 'regulated',
                                          start_date: DateTime.current,
                                          due_date: DateTime.current + 1.hour })
      end

      it 'displays an error message' do
        put_mission

        expect(response.body).to include(I18n.t('activerecord.errors.models.mission.attributes.duration.multiple'))
      end
    end

    context "when the mission have several enrollments and the datetimes of the related enrollments are outside
    of the new mission's period" do
      let(:create_enrollments) do
        create_list :enrollment,
                    3,
                    start_time: mission.start_date,
                    end_time: mission.due_date,
                    member_id: (create :member).id,
                    mission_id: mission.id
      end

      let(:mission_params) do
        generate_attributes_for_mission({ name: 'updated_mission',
                                          start_date: mission.start_date + 3.hours,
                                          due_date: mission.due_date + 3.hours })
      end

      let(:expected_params) { { start_date: mission_params['start_date'], due_date: mission_params['due_date'] } }
      let(:i18n_key) { 'activerecord.errors.models.mission.inconsistent_datetimes_for_related_enrollments' }

      it 'displays an error message' do
        create_enrollments

        put_mission

        expect(response.body).to include(I18n.t(i18n_key))
      end
    end

    context "when the :regulate type is passed in params and the datetimes of the related enrollments
    mismatch the mission's time_slots" do
      let(:mission_params) do
        generate_attributes_for_mission({ name: 'updated_mission',
                                          start_date: mission.start_date,
                                          due_date: mission.due_date,
                                          genre: 'regulated' })
      end

      let(:create_enrollments) do
        create_list :enrollment,
                    3,
                    start_time: mission.start_date + 1.hour,
                    end_time: mission.start_date + 2.hours,
                    member_id: (create :member).id,
                    mission_id: mission.id
      end

      let(:i18n_key) { 'activerecord.errors.models.mission.mismatch_between_time_slots_and_related_enrollments' }

      it 'displays a error message' do
        create_enrollments

        put_mission

        expect(response.body).to include(I18n.t(i18n_key))
      end
    end

    context "when the mission is :regulate, new datetimes are passed in params and the datetimes of the related
    enrollments mismatch the time_slots of the new mission's period" do
      let(:mission) { create :mission, start_date: DateTime.current + 2.days, genre: 'regulated' }

      let(:mission_params) do
        generate_attributes_for_mission({ name: 'updated_mission',
                                          start_date: mission.start_date - 1.hour,
                                          due_date: mission.due_date - 1.hour })
      end

      let(:create_enrollments) do
        create_list :enrollment,
                    3,
                    start_time: mission.start_date,
                    end_time: mission.start_date + 90.minutes,
                    member_id: (create :member).id,
                    mission_id: mission.id
      end

      let(:i18n_key) { 'activerecord.errors.models.mission.mismatch_between_time_slots_and_related_enrollments' }

      it 'displays a error message' do
        create_enrollments

        put_mission

        expect(response.body).to include(I18n.t(i18n_key))
      end
    end

    context 'when the recurrent changes params is true' do
      let(:mission_params) do
        generate_attributes_for_mission({ name: 'updated_mission',
                                          recurrent_change: true,
                                          start_date: mission.start_date + 3.hours,
                                          due_date: mission.due_date + 3.hours })
      end

      let(:all_missions) { create_future_matching_missions(mission) + [mission] }
      let!(:expected_start_dates) { all_missions.map(&:start_date) }
      let!(:expected_due_dates) { all_missions.map(&:due_date) }

      it 'updates futures missions that match the same week day, hour, and genre' do # rubocop:disable Layout/LineLength
        other_missions = create_future_matching_missions(mission)

        put_mission

        other_missions.each do |mission|
          expect(mission.reload.name).to eq 'updated_mission'
        end
      end

      it "doesn't update pasts missions that match the same week day, hour, and genre" do # rubocop:disable Layout/LineLength
        other_mission = create :mission, start_date: mission.start_date - 2.days

        put_mission

        expect(other_mission.reload.name).not_to eq 'updated_mission'
      end

      it "doesn't update :start_date attribute" do
        put_mission

        all_missions.each_with_index do |current_mission, index|
          expect(current_mission.reload.start_date).to eq(expected_start_dates[index])
        end
      end

      it "doesn't update :due_date attribute" do
        put_mission

        all_missions.each_with_index do |current_mission, index|
          expect(current_mission.reload.due_date).to eq(expected_due_dates[index])
        end
      end
    end
  end

  # helpers

  def create_history_of_generated_schedule_for_n_months(months_count)
    (1..months_count).each do |n|
      create :history_of_generated_schedule,
             month_number: (DateTime.current + n.month).at_beginning_of_month
    end
  end

  def create_future_matching_missions(mission)
    occurrence_date = mission.start_date + 7.days
    other_missions = []
    4.times do
      other_missions << create(:mission, start_date: occurrence_date, genre: mission.genre)
      occurrence_date += 7.days
    end
    other_missions
  end

  def generate_attributes_for_mission(params)
    attributes = attributes_for :mission, params
    attributes.merge!(convert_datetime_in_datepicker_params(attributes[:start_date], 'start_date'))
    attributes.merge!(convert_datetime_in_datepicker_params(attributes[:due_date], 'due_date'))
    attributes.delete(:start_date)
    attributes.delete(:due_date)
    attributes
  end

  def convert_datetime_in_datepicker_params(datetime, key)
    {
      "#{key}(1i)": datetime.year,
      "#{key}(2i)": datetime.month,
      "#{key}(3i)": datetime.day,
      "#{key}(4i)": datetime.hour,
      "#{key}(5i)": datetime.min
    }
  end
end
