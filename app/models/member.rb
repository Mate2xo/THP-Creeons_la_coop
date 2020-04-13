# frozen_string_literal: true

# == Schema Information
#
# Table name: members
#
#  id                        :bigint(8)        not null, primary key
#  email                     :string           default(""), not null
#  encrypted_password        :string           default(""), not null
#  reset_password_token      :string
#  reset_password_sent_at    :datetime
#  remember_created_at       :datetime
#  first_name                :string
#  last_name                 :string
#  biography                 :text
#  phone_number              :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  role                      :integer          default("member")
#  confirmation_token        :string
#  confirmed_at              :datetime
#  confirmation_sent_at      :datetime
#  unconfirmed_email         :string
#  group                     :integer
#  invitation_token          :string
#  invitation_created_at     :datetime
#  invitation_sent_at        :datetime
#  invitation_accepted_at    :datetime
#  end_subscription          :date
#  invitation_limit          :integer
#  invited_by_type           :string
#  invited_by_id             :bigint(8)
#  invitations_count         :integer          default(0)
#  display_name              :string
#  moderator                 :boolean          default(FALSE)
#  cash_register_proficiency :integer          default("untrained")
#

# The websites users. Their 'role' attributes determines if fhey're an unvalidated user, a member, admin or super-admin
class Member < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  has_one_attached :avatar

  has_one :address, dependent: :destroy
  accepts_nested_attributes_for :address, reject_if: :all_blank, allow_destroy: true

  has_many :created_missions, class_name: 'Mission', inverse_of: 'author', foreign_key: 'author_id', dependent: :nullify
  has_many :enrollments, dependent: :destroy
  has_many :missions, through: :enrollments

  has_many :created_infos, class_name: 'Info', inverse_of: 'author', foreign_key: 'author_id', dependent: :nullify

  has_and_belongs_to_many :managed_productors, class_name: "Productor"

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :display_name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 50 }

  before_validation :set_unique_display_name

  enum role: { member: 0, admin: 1, super_admin: 2 }
  enum group: {
    welcome: 1,
    financial_management: 2,
    members_management: 3,
    core: 4,
    schedule: 5,
    diy: 6,
    internal_culture: 7,
    local_suppliers: 8,
    other_suppliers: 9,
    supply: 10,
    orders_management: 11,
    it: 12
  }
  enum cash_register_proficiency: { untrained: 0, beginner: 1, proficient: 2 }

  def thredded_admin?
    admin? || super_admin?
  end

  def renew_subscription_date
    base = if end_subscription.nil? || end_subscription < Date.today
             Date.today
           else
             end_subscription + 1
           end

    self.end_subscription = if leap_subscription?(base)
                              base + 365
                            else
                              base + 364
                            end
    save
end

  private

  def set_unique_display_name
    return unless display_name.nil? || changed.any?('first_name') || changed.any?('last_name')

    display_name = "#{first_name} #{last_name}"

    i = 0
    while Member.exists?(display_name: display_name)
      display_name = "#{first_name} #{last_name} #{i += 1}"
    end

    self.display_name = display_name
  end

  def leap_subscription?(base)
    return true if base.leap? && base.month <= 2

    return true if (base + 365).leap? && base.month > 2

    false
  end
end
