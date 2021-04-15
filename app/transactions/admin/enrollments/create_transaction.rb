# frozen_string_literal: true

module Admin
  module Enrollments
    # Create enrolment after a dateTimes validation
    class CreateTransaction # rubocop:disable Metrics/ClassLength
      include Dry::Transaction

      step :validation
      step :create_enrollment

      private

      def validation(enrollment) # rubocop:disable Metrics/AbcSize
        enrollment.check_if_member_is_already_enrolled
        enrollment.check_if_the_standard_mission_is_not_full
        enrollment.check_if_the_duration_is_positive
        enrollment.check_if_datetimes_of_enrollment_are_inside_the_mission_s_period
        enrollment.check_if_enrollment_is_matching_the_mission_s_timeslots
        enrollment.check_slots_availability_for_regulated_mission
        enrollment.check_cash_register_proficiency
        return Failure(enrollment.errors.values.flatten[0]) if enrollment.errors.present?

        Success(enrollment)
      end

      def check_if_member_is_already_enrolled(input)
        mission = input.mission
        member = input.member
        failure_message = I18n.t('activerecord.errors.models.enrollment.member_already_enrolled')

        return Failure(failure_message) if mission.members.include?(member)

        Success(input)
      end

      def check_if_the_standard_mission_is_not_full(input)
        mission = input.mission

        failure_message = I18n.t('activerecord.errors.models.enrollment.full_mission')
        return Success(input) if mission.genre != 'standard'
        return Failure(failure_message) unless mission.members.count < mission.max_member_count

        Success(input)
      end

      def check_if_the_duration_is_positive(input)
        failure_message = I18n.t('activerecord.errors.models.enrollment.negative_duration')
        return Failure(failure_message) unless input.start_time < input.end_time

        Success(input)
      end

      def check_if_datetimes_of_enrollment_are_inside_the_mission_s_period(input)
        failure_message = I18n.t('activerecord.errors.models.enrollment.inconsistent_datetimes')
        mission = input.mission
        return Failure(failure_message) unless input[:start_time] >= mission.start_date &&
                                               input[:start_time] <= mission.due_date &&
                                               input[:end_time] >= mission.start_date &&
                                               input[:end_time] <= mission.due_date

        Success(input)
      end

      def check_if_enrollment_is_matching_the_mission_s_timeslots(input)
        return Success(input) unless input.mission.genre == 'regulated'

        failure_message = I18n.t('activerecord.errors.models.enrollment.time_slot_mismatch')
        return Failure(failure_message) unless match_a_time_slot?(input)

        Success(input)
      end

      def check_slot_availability_for_regulated_mission(input)
        failure_message = I18n.t('activerecord.errors.models.enrollment.slot_unavailability')
        return Success(input) if input.mission.genre != 'regulated'

        return Failure(failure_message) unless are_all_timeslots_selected_by_enrollment_available?(input)

        Success(input)
      end

      def check_cash_register_proficiency(input)
        return Success(input) unless input.mission.genre == 'regulated'

        failure_message = I18n.t('activerecord.errors.models.enrollment.insufficient_cash_register_mastery')
        return Failure(failure_message) unless slot_available_for_given_cash_register_proficiency?(input)

        Success(input)
      end

      def create_enrollment(input)
        failure_message = I18n.t('activerecord.errors.messages.update_fail')
        return Failure(failure_message) unless Enrollment.create(input.attributes).valid?

        Success(input)
      end

      # helpers

      def minimum_cash_register_proficiency_requirement_satisfied?(input)
        mission = input.mission
        member = input.member

        mastery_level_of_member = Member.cash_register_proficiencies[member.cash_register_proficiency]

        proficiency_requirement = mission.cash_register_proficiency_requirement
        mastery_level_of_mission = Mission.cash_register_proficiency_requirements[proficiency_requirement]

        mastery_level_of_member >= mastery_level_of_mission
      end
    end
  end
end
