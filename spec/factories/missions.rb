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
#

FactoryBot.define do
  factory :mission do
    name { Faker::Company.bs }
    description { Faker::Lorem.paragraph }
    max_member_count { 4 }
    min_member_count { 1 }
    start_date do
      Faker::Time.between_dates(from: Date.current.at_beginning_of_week,
                                to: Date.current.at_end_of_week,
                                period: :day)
                 .beginning_of_minute
                 .to_datetime
    end
    due_date { start_date + 3.hours }
    association :author, factory: :member
  end
end
