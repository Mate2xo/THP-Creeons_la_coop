# frozen_string_literal: true

# == Schema Information
#
# Table name: missions
#
#  id                :bigint(8)        not null, primary key
#  name              :string           not null
#  description       :text             not null
#  due_date          :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  author_id         :bigint(8)
#  start_date        :datetime
#  recurrent         :boolean
#  max_member_count  :integer
#  min_member_count  :integer
#  delivery_expected :boolean          default(FALSE)
#  genre             :integer          default: 0
#  cash_register_proficiency_requirement   :integer          default(0)
#

# A Mission is an activity that has to be done for the Supermaket Team to function properly.
# Every member can create a mission
# Available methods: #addresses, #author, #due_date, #name, #description
# A regulated mission have several time_slots
# A time slot is a subdivision of mission duration
# A time slot last 90 minutes
# A time slot have several slots
# Slots count for a time slot is equal to :max_member_count
class Mission < ApplicationRecord
  belongs_to :author, class_name: 'Member', inverse_of: 'created_missions', optional: true
  has_many :enrollments, dependent: :destroy
  has_many :members, through: :enrollments
  has_and_belongs_to_many :productors
  has_and_belongs_to_many :addresses

  validates :name, presence: true
  validates :description, presence: true
  validates :start_date, presence: true
  validates :due_date, presence: true
  validates :min_member_count, numericality: { only_integer: true }, presence: true
  validates :max_member_count, numericality: { only_integer: true }, allow_nil: true
  validates :genre, presence: true
  validates_with DurationValidator

  accepts_nested_attributes_for :addresses, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :enrollments, reject_if: :all_blank, allow_destroy: true

  enum genre: { standard: 0, regulated: 1, event: 2 }

  enum cash_register_proficiency_requirement: { untrained: 0, beginner: 1, proficient: 2 }

  # Virtual attributes
  attr_accessor :recurrence_rule
  attr_accessor :recurrence_end_date
  attr_accessor :recurrent_change

  def duration
    (due_date - start_date).round
  end

  def regulated?
    (genre == 'regulated')
  end

  def standard_full?
    return nil unless genre == 'standard'

    max_member_count == members.count
  end

  def selectable_time_slots(member = nil)
    return nil unless genre == 'regulated'

    time_slots = []
    current_time_slot = start_date
    while current_time_slot < due_date
      time_slots << current_time_slot if time_slot_selectable?(current_time_slot, member)
      current_time_slot += 90.minutes
    end
    time_slots
  end

  def time_slot_already_taken_by_member?(current_time_slot, member)
    member_enrollment = enrollments.find_by(mission: self, member: member)
    return false if member_enrollment.nil?

    member_enrollment.contain_this_time_slot?(current_time_slot)
  end

  def available_slots_count_for_a_time_slot(time_slot)
    occupied_slots_count = enrollments.where('start_time <= :time_slot AND :time_slot < end_time',
                                             time_slot: time_slot).count
    max_member_count - occupied_slots_count
  end

  def inside_period?(enrollment)
    enrollment.start_time >= start_date &&
      enrollment.start_time <= due_date &&
      enrollment.end_time >= start_date &&
      enrollment.end_time <= due_date
  end

  def match_a_time_slot?(enrollment)
    current_time_slot = start_date
    while current_time_slot < due_date
      return true if current_time_slot == enrollment.start_time

      current_time_slot += 90.minutes
    end
    false
  end

  def all_timeslots_covered_by_enrollment_available?(enrollment)
    return nil unless regulated?

    current_time_slot = enrollment.start_time
    while current_time_slot < enrollment.end_time
      return false if available_slots_count_for_a_time_slot(current_time_slot).zero?

      current_time_slot += 90.minutes
    end
    true
  end

  def slot_available_for_given_cash_register_proficiency?(enrollment, cash_register_proficiency_level)
    current_time_slot = enrollment.start_time
    proficiency_level_of_mission = Mission.cash_register_proficiency_requirements[cash_register_proficiency_requirement]

    while current_time_slot < enrollment.end_time
      if available_slots_count_for_a_time_slot(current_time_slot) == 1 &&
         (cash_register_proficiency_level < proficiency_level_of_mission)
        return false
      end

      current_time_slot += 90.minutes
    end

    true
  end

  # validation methods

  def check_if_enrollments_are_inside_new_mission_s_period
    failure_message = I18n.t('activerecord.errors.models.mission.inconsistent_datetimes_for_related_enrollments')
    enrollments.each do |enrollment|
      unless inside_period?(enrollment)
        errors.add :inconsistent_datetimes_for_related_enrollments, failure_message
        return false
      end
    end
    true
  end

  def check_if_enrollments_match_a_mission_s_time_slots_for_regulated_mission
    failure_message = I18n.t('mismatch_between_time_slots_and_related_enrollments',
                             scope: %i[activerecord errors models mission])
    enrollments.each do |enrollment|
      unless match_a_time_slot?(enrollment)
        errors.add :mismatch_between_time_slots_and_related_enrollments, failure_message
        return false
      end
    end
    true
  end

  private

  def time_slot_selectable?(current_time_slot, member)
    return true if member.present? && time_slot_already_taken_by_member?(current_time_slot, member)

    time_slot_available?(current_time_slot)
  end

  def time_slot_available?(current_time_slot)
    enrollments.where('start_time <= :current_time_slot AND :current_time_slot < end_time',
                      current_time_slot: current_time_slot)
               .count < max_member_count
  end
end
