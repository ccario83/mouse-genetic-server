class User < ActiveRecord::Base
	attr_accessible :first_name, :last_name, :institution, :email, :password, :password_confirmation
	has_secure_password
	has_many :microposts, :dependent => :destroy
	has_many :relationships, :foreign_key => "follower_id", :dependent => :destroy
	has_many :followed_users, :through => :relationships, :source => :followed
	has_many :reverse_relationships, :foreign_key => "followed_id", :class_name => "Relationship", :dependent => :destroy
	has_many :followers, :through => :reverse_relationships, :source => :follower

	before_save { |user| user.email = user.email.downcase }
	before_save :create_remember_token

	validates :first_name, 	:presence => true, :length => { :maximum => 50 }
	validates :last_name, 	:presence => true, :length => { :maximum => 50 }
	validates :institution,	:presence => true, :length => { :maximum => 50 }
	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
	validates :email, :presence => true, :format => { :with => VALID_EMAIL_REGEX }, :uniqueness => { :case_sensitive => false}
	validates :password, :length => { :minimum => 6 }
	validates :password_confirmation, :presence => true 

	def name
		"#{self.first_name} #{self.last_name}"
	end

	def feed
		Micropost.from_users_followed_by(self)
		# Micropost.where("user_id =?", id)
	end

	def following?(other_user)
		self.relationships.find_by_followed_id(other_user.id)
	end

	def follow!(other_user)
		self.relationships.create!(followed_id: other_user.id)
	end

	def unfollow!(other_user)
		relationships.find_by_followed_id(other_user.id).destroy
	end

	private
		def create_remember_token
			self.remember_token = SecureRandom.base64
		end

	# Set the number of users per page for will_paginate
	self.per_page = 9
end
