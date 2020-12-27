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
#  event             :boolean          default(FALSE)
#  genre             :integer          default: 0
#

# A Mission is an activity that has to be done for the Supermaket Team to function properly.
# Every member can create a mission
# Available methods: #addresses, #author, #due_date, #name, #description
class Mission < ApplicationRecord
  belongs_to :author, class_name: 'Member', inverse_of: 'created_missions'
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

  # Virtual attributes
  attr_accessor :recurrence_rule
  attr_accessor :recurrence_end_date

  def duration
    (due_date - start_date).round
  end

  def available_time_slots(member = nil)
    return nil unless genre == 'regulated'

    time_slots = []
    current_time_slot = start_date
    while current_time_slot < due_date
      time_slots << current_time_slot if time_slot_available?(current_time_slot, member)
      current_time_slot += 90.minutes
    end
    time_slots
  end

  private

  def time_slot_available?(current_time_slot, member)
    member_enrollment = enrollments.find_by(mission: self, member: member)
    if member.nil? || member_enrollment.nil?
      return enrollments.where('start_time <= :current_time_slot AND :current_time_slot < end_time',
                               current_time_slot: current_time_slot)
                        .count < max_member_count
    end

    return true if member.present? && member_enrollment.decorate.already_taken?(current_time_slot)
  end
end
