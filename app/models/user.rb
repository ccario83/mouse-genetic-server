require 'will_paginate/array'

class User < ActiveRecord::Base
	attr_accessible :first_name, :last_name, :institution, :email, :password, :password_confirmation
	before_save { |user| user.email = user.email.downcase }
	before_save :create_remember_token
	has_secure_password
	

	# A user has many microposts using the communication polymorphic relationship (recipient_id, recipient_type columns)
	has_many :authored_posts, :class_name => 'Micropost', :foreign_key => 'creator_id', :dependent => :destroy
	# Microposts are called received_posts (of type Micropost) and are found through the communication model
	has_many :communications, :as => :recipient
	has_many :received_posts, :source => :micropost, :through => :communications, :dependent => :destroy

	# Group/membership relations
	has_many :memberships
	has_many :groups, :through => :memberships

	# Task relations
	has_many :created_tasks, :class_name => 'Task', :foreign_key => 'creator_id'
	has_many :assigned_tasks, :class_name => 'Task', :foreign_key => 'assignee_id'

	# Validations
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


	#def post_message(message, *p )
		#if (groups.empty? and users.empty?)
		#	return # Or should let model validation fail?
		#end
	#	groups = groups.is_a?(Array) ? groups : [groups]
	#	users = users.is_a?(Array) ? users : [users]
	#	Micropost.create!(:creator => self, :content => message, :user_recipients => users, :group_recipients => groups)
	#end


	## THESE SHOULD BE DEPRECIATED ONCE ALL VIEWS USE post_message FUNCTION
	# A function alias to make the calls more comfortable to the user
	def post_message_to_group(group, message)
		post_message_to_groups(group, message)
	end

	# Takes a message as a string and posts it to a group or list groups
	def post_message_to_groups(groups, message)
		groups = groups.is_a?(Array) ? groups : [groups]
		Micropost.create!(:creator => self, :content => message, :group_recipients => groups)
	end
	
	# A function alias to make the calls more comfortable to the user
	def post_message_to_user(user, message)
		post_message_to_users(user, message)
	end

	# Takes a message as a string and posts it to a user or list users
	def post_message_to_users(users, message)
		users = users.is_a?(Array) ? users : [users]
		Micropost.create!(:creator => self, :content => message, :user_recipients => users)
	end





	def group_received_posts
		microposts = self.groups.map(&:received_posts).flatten
		microposts.sort_by(&:created_at)
		return microposts
	end

	def all_received_posts
		microposts = self.received_posts + self.group_received_posts
		microposts.sort_by(&:created_at)
		return microposts
	end
	
	def confirm_membership(group)
		if group.is_member?(self)
			self.memberships.where(:group_id => group.id)[0].update_attributes(:confirmed => true)
		end
	end

	def confirmed_groups
		Group.find(self.memberships.where(:confirmed => true).map(&:group_id))
	end
	
	def is_member?(group)
		group.users.include?(self)
	end
	
	def confirmed_member?(group)
		@confirmation = group.memberships.select(:confirmed).where(:user_id => self.id)[0]
		return (defined?(@confirmation.confirmed).nil?)? false : @confirmation.confirmed
	end

	private
		def create_remember_token
			self.remember_token = SecureRandom.base64
		end

end

