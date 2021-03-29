# frozen_string_literal: true

# This namespace contains all tasks related to the mission model
namespace :mission do # rubocop:disable Metrics/BlockLength
  desc "set futur mission with the :name 'permanence clac' to :regulated"
  task set_missions_to_regulated: :environment do
    missions = Mission.where('start_date > ? and genre = ? and name = ?',
                             DateTime.current + 1.day,
                             0,
                             'permanence clac')
    missions.each do |mission|
      unless match_all_enrollment_a_time_slot?(mission)
        puts("the mission at #{mission.start_date} has not been setted, an enrollment mismatch the mission's timeslots")
        next
      end

      puts("the mission at #{mission.start_date} has been setted") if mission.update(genre: 1)
    end
  end

  def match_all_enrollment_a_time_slot?(mission)
    mission.enrollments.each do |enrollment|
      return false unless ((enrollment.end_time.to_i - enrollment.start_time.to_i) % (60 * 90)).zero?
      return false unless match_a_time_slot?(mission, enrollment)
    end
    true
  end

  def match_a_time_slot?(mission, enrollment)
    current_time_slot = mission.start_date
    while current_time_slot < mission.due_date
      return true if current_time_slot == enrollment.start_time

      current_time_slot += 90.minutes
    end
    false
  end
end
