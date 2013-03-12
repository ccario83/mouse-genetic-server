class Group < ActiveRecord::Base
	attr_accessible :description, :name, :users, :creator

	# User/membership relations
	has_many :memberships
	# A group has many users, and users have many groups, initally the user/group combination has a false confirmation status until the user OKs membership
	has_many :users, :through => :memberships
	# A group also has a creator, but we will access a user directly though the creator_id column in this table
	belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id'
	
	# Micropost relations
	has_many :microposts, :as => :recipient 
	
	# Task relations
	has_many :tasks

	# Validations
	validates :creator_id, :presence => true
	validates :name, :presence => true, :length => {:maximum => 25 }, :uniqueness => { :case_sensitive => true}
	validates :description,	:presence => true, :length => { :maximum => 150 }
	
	# Maybe a little friendlier than group.users
	def members
		self.users
	end
	
	def is_member?(user)
		self.memberships.include?(user)
	end
	
	def confirmed_member?(user)
		@confirmation = self.memberships.select(:confirmed).where(:user_id => user.id)[0]
		return (defined?(@confirmation.confirmed).nil?)? false : @confirmation.confirmed
	end
end

