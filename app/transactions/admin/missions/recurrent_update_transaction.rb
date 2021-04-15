# frozen_string_literal: true

module Admin
  module Missions
    # update mission and update recurrently if the recurrent change params is given
    class RecurrentUpdateTransaction
      include Dry::Transaction

      around :rollback_if_failure

      tee :remove_datetime_attributes
      tee :get_missions_with_same_time_slot
      step :update_all_missions

      private

      def rollback_if_failure(input, &block)
        result = nil

        Mission.transaction do
          result = block.call(Success(input))
          raise ActiveRecord::Rollback if result.failure?

          result
        end
        result
      end

      # For recurrent changes, we only update non time-related attributes to not mess with individual
      # time slots validations. Time slots validation's responsibility belongs to each individual missions
      def remove_datetime_attributes(input)
        input[:params].delete(:start_date)
        input[:params].delete(:due_date)
        remove_activeadmin_datepicker_params(input, 'start_date')
        remove_activeadmin_datepicker_params(input, 'due_date')
        input[:params].delete(:recurrent_change)

        Success(input)
      end

      def get_missions_with_same_time_slot(input)
        mission = input[:mission]

        input.merge!({ all_missions: all_missions(mission) })
        Success(input)
      end

      def update_all_missions(input)
        all_missions = input[:all_missions]

        all_missions.each do |current_mission|
          transaction_result = Admin::Missions::UpdateTransaction
                               .new
                               .call(build_mission_input(current_mission, input[:params]))
          next if transaction_result.success?

          return Failure(determine_failure_message(transaction_result.failure, current_mission))
        end
        Success(input)
      end

      # helpers

      def all_missions(mission)
        all_missions = Mission.where('start_date >= :mission_start_date AND genre = :mission_genre',
                                     mission_start_date: mission.start_date,
                                     mission_genre: Mission.genres[mission.genre])
        all_missions.select do |current_mission|
          current_mission.start_date.strftime('%R%u') == mission.start_date.strftime('%R%u')
        end
      end

      def determine_failure_message(failure, mission)
        I18n.t('activerecord.errors.models.mission.recurrent_update_cancel',
               name: mission.name,
               start_date: mission.start_date,
               failure: failure)
      end

      def build_mission_input(mission, params)
        params[:start_date] = mission.start_date
        params[:due_date] = mission.due_date
        { params: params, mission: mission }
      end

      def remove_activeadmin_datepicker_params(input, key)
        input[:params].delete("#{key}(1i)")
        input[:params].delete("#{key}(2i)")
        input[:params].delete("#{key}(3i)")
        input[:params].delete("#{key}(4i)")
        input[:params].delete("#{key}(5i)")
      end
    end
  end
end
