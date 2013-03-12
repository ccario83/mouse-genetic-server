class Membership < ActiveRecord::Base
	attr_accessible :confirmed
	
	belongs_to :group
	belongs_to :user

end

