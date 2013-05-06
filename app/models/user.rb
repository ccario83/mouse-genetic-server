require 'will_paginate/array'
require 'find'

class User < ActiveRecord::Base
	attr_accessible :first_name, :last_name, :institution, :email, :password, :password_confirmation, :directory
	before_save { |user| user.email = user.email.downcase }
	before_save :create_remember_token
	has_secure_password
	before_create :create_user_directory


	# A user has many microposts using the communication polymorphic relationship (recipient_id, recipient_type columns)
	has_many :authored_posts, :class_name => 'Micropost', :foreign_key => 'creator_id', :dependent => :destroy
	# Microposts are called received_posts (of type Micropost) and are found through the communication model
	has_many :communications, :as => :recipient
	has_many :received_posts, :source => :micropost, :through => :communications, :dependent => :destroy

	# Group/membership relations
	has_many :memberships, :dependent => :destroy
	has_many :groups, :through => :memberships

	# Task relations
	has_many :created_tasks, :class_name => 'Task', :foreign_key => 'creator_id', :dependent => :destroy
	has_many :assigned_tasks, :class_name => 'Task', :foreign_key => 'assignee_id', :dependent => :destroy

	# Job relation
	has_many :jobs, :class_name => 'Job', :foreign_key => 'creator_id', :dependent => :destroy
	
	# Data relation
	has_many :datafiles, :class_name => 'Datafile', :foreign_key => 'owner_id', :dependent => :destroy

	# Validations
	validates :first_name,	:presence => true, :length => { :maximum => 50 }
	validates :last_name, 	:presence => true, :length => { :maximum => 50 }
	validates :institution,	:presence => true, :length => { :maximum => 50 }
	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
	validates :email, :presence => true, :format => { :with => VALID_EMAIL_REGEX }, :uniqueness => { :case_sensitive => false}, :uniqueness => true
	validates :password, :presence => {:on => :create}, :confirmation => true, :length => { :minimum => 5}

	def name
		"#{self.first_name} #{self.last_name}"
	end


	## THESE SHOULD BE DEPRECIATED ONCE ALL VIEWS USE post_message FUNCTION
	# A function alias to make the calls more comfortable to the user
	def post_message_to_group(group, message)
		post_message_to_groups(group, message)
	end

	# Takes a message as a string and posts it to a group or list groups
	def post_message_to_groups(groups, message)
		groups = groups.is_a?(Array) ? groups : [groups]
		post = Micropost.new(:creator => self, :content => message, :group_recipients => groups)

		if post.save
			return true
		else
			return false
		end
	end
	
	# A function alias to make the calls more comfortable to the user
	def post_message_to_user(user, message)
		post_message_to_users(user, message)
	end

	# Takes a message as a string and posts it to a user or list users
	def post_message_to_users(users, message)
		users = users.is_a?(Array) ? users : [users]
		post = Micropost.new(:creator => self, :content => message, :user_recipients => users)
		if post.save
			return true
		else
			return false
		end
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

	def used_quota?
		total = 0
		Find.find(self.directory) {|f| total += File.directory?(f) ? 0 : File.size(f)}
		total = total.to_f / 2**30 
		total /= USER_DISK_QUOTA
		return total >= 100.0
	end
	
	def redis_key
		# A good UNIX filename expression: /^.*\/(.[^\/`"':]+)$/
		return self.directory.split(/^.*\/([\.a-zA-Z0-9]+)$/)[1]
	end


	private
		def create_remember_token
			self.remember_token = SecureRandom.base64
		end

		def create_user_directory
			# Create a subdirectory that is a combination of the user name alpha characters and a small hex key
			subdir = self.last_name.downcase.gsub(/[^a-z]/, '') + '.' + self.first_name.downcase.gsub(/[^a-z]/, '') + '.' + SecureRandom.hex(3)
			# Try to create a directory for this job using the id as a directory name
			directory = File.join(USER_DATA_PATH, subdir)
			begin
				Dir.mkdir(directory) unless File.directory?(directory)
				Dir.mkdir(File.join(directory,'data')) unless File.directory?(File.join(directory,'data'))
				Dir.mkdir(File.join(directory,'jobs')) unless File.directory?(File.join(directory,'jobs'))
			rescue
				errors.add_to_base('There was an issue creating this user account. Please contact the web administrator.')
			end
			self.directory = directory
		end
end

