# frozen_string_literal: true

ActiveAdmin.register Member do
  permit_params :email, :encrypted_password, :first_name, :last_name, :biography, :phone_number, :role, :confirmed_at, :password, :password_confirmation

  index do
    selectable_column
    column :first_name
    column :last_name
    column :role
    column :group
    column :email
    actions
  end

  form do |f|
    f.inputs :first_name, :last_name, :email, :role, :group, :phone_number, :biography
    actions
  end

  filter :email
  filter :first_name
  filter :last_name
  filter :email
  filter :role
  filter :group
end
