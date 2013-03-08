require 'will_paginate/array'

class User < ActiveRecord::Base
	attr_accessible :first_name, :last_name, :institution, :email, :password, :password_confirmation
	has_secure_password
	has_many :recieved_posts, :class_name => 'Micropost', :as => :recipient # A user can have microposts through micropost recipients
	has_many :authored_posts, :class_name => 'Micropost', :foreign_key => 'creator_id'
	has_and_belongs_to_many :groups
	has_many :created_tasks, :class_name => 'Task', :foreign_key => 'creator_id'
	has_many :assigned_tasks, :class_name => 'Task', :foreign_key => 'assignee_id'

	before_save { |user| user.email = user.email.downcase }
	before_save :create_remember_token

	validates :first_name,	:presence => true, :length => { :maximum => 50 }
	validates :last_name, 	:presence => true, :length => { :maximum => 50 }
	validates :institution,	:presence => true, :length => { :maximum => 50 }
	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
	validates :email, :presence => true, :format => { :with => VALID_EMAIL_REGEX }, :uniqueness => { :case_sensitive => false}
	validates :password, :length => { :minimum => 6 }
	validates :password_confirmation, :presence => true 

	def name
		"#{self.first_name} #{self.last_name}"
	end

	def post_message_to_group(group, message)
		self.authored_posts.create!(:content => message, :recipient_id => group.id, :recipient_type => 'Group')
	end
	
	def post_message_to_user(user, message)
		self.authored_posts.create!(:content => message, :recipient_id => user.id, :recipient_type => 'User')
	end

	def group_recieved_posts
		microposts = self.groups.map(&:microposts).flatten
		return microposts
	end

	def all_recieved_posts
		microposts = self.recieved_posts + self.groups.map(&:microposts).flatten
		microposts.sort_by(&:created_at)
		return microposts
	end

	private
		def create_remember_token
			self.remember_token = SecureRandom.base64
		end

end
