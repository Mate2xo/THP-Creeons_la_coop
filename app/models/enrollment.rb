# frozen_string_literal: true

# == Schema Information
#
# Table name: enrollments
#
#  member_id  :bigint(8)        not null
#  mission_id :bigint(8)        not null
#  id         :bigint(8)        not null, primary key
#  start_time :time
#  end_time   :time
#

# Represents a member enrolling to a given Mission
class Enrollment < ApplicationRecord
  belongs_to :member
  belongs_to :mission

  before_save :set_defaults

  def duration
    return 0 if start_time == nil || end_time == nil

    ((end_time - start_time) / 60 / 60).round 1
  end

  def contain_this_time_slot?(time_slot)
    start_time <= time_slot && time_slot < end_time
  end

  def check_if_member_is_already_enrolled
    if mission.members.include?(member)
      failure_message = I18n.t('activerecord.errors.models.enrollment.member_already_enrolled')
      errors.add :member_already_enrolled, failure_message
      return false
    end

    true
  end

  def check_if_the_standard_mission_is_not_full
    return true unless mission.genre == 'standard'

    if mission.standard_full?
      failure_message = I18n.t('activerecord.errors.models.enrollment.full_mission')
      errors.add :full_mission, failure_message
      return false
    end

    true
  end

  def check_if_the_duration_is_positive
    if start_time >= end_time
      failure_message = I18n.t('activerecord.errors.models.enrollment.negative_duration')
      errors.add :negative_duration, failure_message
      return false
    end

    true
  end

  def duration_multiple_of_90_minutes?
    ((end_time.to_i - start_time.to_i) % (60 * 90)).zero?
  end

  def check_if_datetimes_of_enrollment_are_inside_the_mission_s_period
    unless mission.inside_period?(self)
      failure_message = I18n.t('activerecord.errors.models.enrollment.inconsistent_datetimes')
      errors.add :inconsistent_datetimes, failure_message
      return false
    end

    true
  end

  def check_if_enrollment_is_matching_the_mission_s_timeslots
    return true unless mission.regulated?

    unless mission.match_a_time_slot?(self) && duration_multiple_of_90_minutes?
      failure_message = I18n.t('activerecord.errors.models.enrollment.time_slot_mismatch')
      errors.add :time_slot_mismatch, failure_message

      return false
    end

    true
  end

  def check_slots_availability_for_regulated_mission
    return true unless mission.regulated?

    unless mission.all_timeslots_covered_by_enrollment_available?(self)
      failure_message = I18n.t('activerecord.errors.models.enrollment.slot_unavailability')
      errors.add :slot_unavailability, failure_message
      return false
    end

    true
  end

  def check_cash_register_proficiency
    return true unless mission.regulated?

    proficiency_level_of_member = Member.cash_register_proficiencies[member.cash_register_proficiency]
    unless mission.slot_available_for_given_cash_register_proficiency?(self, proficiency_level_of_member)
      failure_message = I18n.t('activerecord.errors.models.enrollment.insufficient_cash_register_proficiency')
      errors.add :insufficient_cash_register_proficiency, failure_message
      return false
    end

    true
  end

  private

  def set_defaults
    self.start_time ||= mission.start_date
    self.end_time ||= mission.due_date
  end
end
