class User < ApplicationRecord
  # MIXINS

  # CONSTANTS

  # ATTRIBUTES
  # Virtual attribute for authenticating by either username or email
  # This is in addition to a real persisted field like 'user_name'
  attr_accessor :login

  # MISCELLANEOUS
  enum role: %i[user editor group_member admin]

  # ASSOCIATIONS
  has_many :submissions, dependent: :destroy
  has_many :plant_images

  has_many :server_jobs, dependent: :destroy
  has_many :ppg_jobs, through: :server_jobs, source: :job, source_type: 'PpgJob'

  # VALIDATIONS
  validates_uniqueness_of :user_name

  # SCOPES

  # CALLBACKS
  after_initialize :set_default_role, if: :new_record?

  # INSTANCE METHODS
  def set_default_role
    self.role ||= :user
  end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # CLASS METHODS
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)
    where(conditions).where(["lower(user_name) = :value OR lower(email) = :value", {value: login.strip.downcase}]).first
  end
end
