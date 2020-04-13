# frozen_string_literal: true

# rubocop: disable Metrics/BlockLength
ActiveAdmin.register Member do
  permit_params :email, :encrypted_password, :first_name, :last_name, :biography,
                :phone_number, :role, :moderator, :group, :confirmed_at,
                :password, :password_confirmation, :cash_register_proficiency
                :end_subscription

  index do
    selectable_column
    column :first_name
    column :last_name
    column :role
    column :group do |member| Member.human_enum_name(:group, member.group) end
    column :cash_register_proficiency
    column :email
    column :end_subscription
    actions
  end

  form do |f|
    f.inputs :first_name, :last_name, :email, :phone_number, :role,
             :moderator, :group, :cash_register_proficiency, :end_subscription,
             :biography
    actions
  end

  filter :email
  filter :first_name
  filter :last_name
  filter :email
  filter :role
  filter :group
  filter :cash_register_proficiency
  filter :end_subscription

  action_item :invite_member, only: :index do
    link_to t("active_admin.invite_member"), new_member_invitation_path
  end

  batch_action :renew, confirm: I18n.t("active_admin.batch_actions.renew_confirmation") do |ids|
    batch_action_collection.find(ids).each do |member|
      member.renew_subscription_date
    end
    redirect_to collection_path, alert: t("active_admin.renew_member_alert")
  end
end
# rubocop: enable Metrics/BlockLength
