class Datafile < ActiveRecord::Base
	attr_accessible :owner, :name, :description, :filename
	
	belongs_to :owner, :class_name => 'User', :foreign_key => 'owner_id'
	has_and_belongs_to_many :groups
end
