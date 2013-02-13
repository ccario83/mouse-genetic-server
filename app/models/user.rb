class User < ActiveRecord::Base
	attr_accessible :first_name, :last_name, :institution, :email, :password, :password_confirmation
	has_secure_password
	has_many :microposts, :dependent => :destroy

	before_save { |user| user.email = user.email.downcase }
	before_save :create_remember_token

	validates :first_name, 	:presence => true, :length => { :maximum => 50 }
	validates :last_name, 	:presence => true, :length => { :maximum => 50 }
	validates :institution,	:presence => true, :length => { :maximum => 50 }
	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
	validates :email, :presence => true, :format => { :with => VALID_EMAIL_REGEX }, :uniqueness => { :case_sensitive => false}
	validates :password, :length => { :minimum => 6 }
	validates :password_confirmation, :presence => true 

	def feed
		# Micropost.from_users_followed_by(self)
		Micropost.where("user_id =?", id)
	end

	def name
		"#{self.first_name} #{self.last_name}"
	end

	private

		def create_remember_token
			self.remember_token = SecureRandom.base64
		end		
end
