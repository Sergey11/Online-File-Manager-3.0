class User < ActiveRecord::Base
  ROLES = %w[user admin]

  attr_accessible :email, :password, :password_confirmation, :remember_me, :role, :provider, :uid, :name
  
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  devise :omniauthable, :omniauth_providers => [:facebook]

  has_many :folders
  has_many :items
  has_many :comments
  has_many :votes

  validates :role, :inclusion => { :in => ROLES }

  before_validation :default_role, :on => :create
  before_create :generate_token


  def self.find_for_facebook_oauth(auth, signed_in_resource=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    unless user
      user = User.create(name:auth.extra.raw_info.name,
                         provider:auth.provider,
                         uid:auth.uid,
                         email:auth.info.email,
                         password:Devise.friendly_token[0,20]
                         )
    end
    user
  end

  def as_api
    info = {}
    user = self
    total_quota = user.quota
    used_quota = user.items.sum(:file_file_size)
    info[:email] = user.email
    info[:total_quota] = total_quota
    info[:used] = used_quota
    info[:left_quota] = total_quota - used_quota
    info
  end

  def admin?
    role == 'admin'
  end

  def can_manage?(target)
    admin? || target.user_id == id
  end

  protected

  def generate_token
    self.token = loop do
      random_token = SecureRandom.urlsafe_base64(nil, false)
      break random_token unless User.exists?(token: random_token)
    end
  end

  private

  def default_role
    self.role = "user"
  end
end
