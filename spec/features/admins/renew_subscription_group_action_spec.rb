# frozen_string_literal: true

require 'rails_helper'

RSpec.feature "RenewSubscriptionGroupAction", type: :feature do
  let(:admin) { create :member, :admin }
  before {
    create_list :member, 10
    sign_in admin
    I18n.locale = :fr
  }

  it "renew selected members" do
    Capybara.current_driver = :selenium
    visit 'admin/members'
    checkboxes = page.find_all(id: /batch_action_item_[0-9]*/)
    checkboxes[2].set(true)
    checkboxes[3].set(true)
    checkboxes[7].set(true)
    checkboxes[5].set(true)
    checkboxes[0].set(true)

    click_on I18n.t("active_admin.batch_actions.button_label")
    click_on I18n.t("active_admin.batch_actions.action_label", title: 'Renouveler les adhésions des')
    click_button "OK"

    expect(page).to have_content I18n.t("active_admin.renew_member_alert")
    Capybara.use_default_driver
  end
end
