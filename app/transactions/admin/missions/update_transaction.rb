# frozen_string_literal: true

module Admin
  module Missions
    # update mission and update recurrently if the recurrent change params is given
    class UpdateTransaction
      include Dry::Transaction

      tee :convert_datepicker_params_in_datetime
      tee :prepare_object
      step :validation
      step :update_mission

      private

      def convert_datepicker_params_in_datetime(input)
        return Success(input) unless input[:params]['start_date(1i)']

        start_date = convert_params_in_datetime(input[:params], 'start_date')
        due_date = convert_params_in_datetime(input[:params], 'due_date')
        input[:params].merge!(start_date: start_date, due_date: due_date)
        Success(input)
      end

      def prepare_object(input)
        mission = input[:mission]
        params = input[:params]

        params.keys.each do |current_key| # rubocop:disable Style/HashEachMethods
          mission[current_key] = params[current_key] if mission.attributes.keys.include?(current_key)
        end
      end

      def validation(input)
        mission = input[:mission]
        mission.check_if_enrollments_are_inside_new_mission_s_period
        mission.check_if_enrollments_match_a_mission_s_time_slots_for_regulated_mission
        return Failure(mission.errors.values.flatten[0]) if mission.errors.present?

        Success(mission)
      end

      def update_mission(mission)
        if mission.save
          Success(mission)
        else
          failure_message = mission.errors.full_messages.join
          Failure(failure_message)
        end
      end

      # helpers

      def convert_params_in_datetime(params, key)
        DateTime.new(
          params["#{key}(1i)"].to_i,
          params["#{key}(2i)"].to_i,
          params["#{key}(3i)"].to_i,
          params["#{key}(4i)"].to_i,
          params["#{key}(5i)"].to_i
        )
      end
    end
  end
end
