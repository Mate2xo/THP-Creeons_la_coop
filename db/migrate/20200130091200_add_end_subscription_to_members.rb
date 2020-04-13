# frozen_string_literal: true

class AddEndSubscriptionToMembers < ActiveRecord::Migration[5.2]
  def change
    add_column :members, :end_subscription, :date
  end
end
