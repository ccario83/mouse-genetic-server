class Job < ActiveRecord::Base
	attr_accessible :creator, :datafile, :users, :groups, :name, :description, :algorithm, :snpset, :location
	
	belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id'
	belongs_to :datafile
	has_and_belongs_to_many :groups
		
end
