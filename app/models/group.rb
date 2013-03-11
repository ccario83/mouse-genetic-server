class Group < ActiveRecord::Base
	attr_accessible :description, :name, :users, :creator

	# A group belongs to the user that created it 
	belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id'
	# A group can have microposts as a micropost recipients
	has_many :microposts, :as => :recipient 
	# A group has many users, and users have many groups, initally the user/group combination has a false confirmation status until the user OKs membership
	has_and_belongs_to_many :users
	# A group has many tasks
	has_many :tasks

	validates :creator_id, :presence => true
	validates :name, :presence => true, :length => {:maximum => 25 }, :uniqueness => { :case_sensitive => true}
	validates :description,	:presence => true, :length => { :maximum => 50 }
	
	# Maybe a little friendlier than group.users
	def members
		self.users
	end
	
end

