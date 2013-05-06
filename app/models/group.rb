class Group < ActiveRecord::Base
	attr_accessible :description, :name, :users, :creator

	# User/membership relations, destroyable with group
	has_many :memberships, :dependent => :destroy
	# A group has many users, and users have many groups, initally the user/group combination has a false confirmation status until the user OKs membership
	has_many :users, :through => :memberships
	# A group also has a creator, but we will access a user directly though the creator_id column in this table
	belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id'
	
	# A group has many microposts using the communication polymorphic relationship (recipient_id, recipient_type columns)
	has_many :communications, :as => :recipient
	# These micrposts are called recieved_posts (of type Micropost) and are found through the communication model
	has_many :received_posts, :source => :micropost, :through => :communications, :dependent => :destroy
	
	# Task relations
	has_many :tasks, :dependent => :destroy

	# Job relation
	has_and_belongs_to_many :jobs
	
	# Data relation
	has_and_belongs_to_many :datafiles

	# Validations
	validates :creator_id, :presence => true
	validates :name, :presence => true, :length => {:maximum => 25 }, :uniqueness => { :case_sensitive => true}
	validates :description,	:presence => true, :length => { :maximum => 150 }
	#validate :membership_size
	
	# Set the default number of posts per page for will_paginate
	self.per_page = 5
	
	# Maybe a little friendlier than group.users
	def members
		self.users
	end
	
	def is_member?(user)
		self.users.include?(user)
	end
	
	def confirmed_member?(user)
		@confirmation = self.memberships.select(:confirmed).where(:user_id => user.id)[0]
		return (defined?(@confirmation.confirmed).nil?)? false : @confirmation.confirmed
	end
	
	def confirmed_members
		return User.find(self.memberships.where(:confirmed => true).map(&:user_id))
	end
	
	def microposts
		return self.received_posts
	end
	
	def all_received_posts
		return self.received_posts.sort_by(&:created_at)
	end
	
	private
	def membership_size
		errors.add(:users, "You cannot create a group with no non-creator members.") unless self.users.length > 2
	end
end

