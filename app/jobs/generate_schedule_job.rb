# frozen_string_literal: true

class GenerateScheduleJob < ApplicationJob # rubocop:disable  Style/Documentation
  queue_as :default

  def perform(params)
    schedule_generator = ScheduleGenerator.new(params[:current_member], params[:current_month].to_datetime)
    schedule_generator.generate_schedule
    return unless schedule_generator.errors.empty?

    HistoryOfGeneratedSchedule.create(month_number: args[0][:current_month].to_datetime)
  end
end
