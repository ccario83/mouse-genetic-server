class Membership < ActiveRecord::Base
	attr_accessible :confirmed, :user_id, :group_id
	
	belongs_to :group
	belongs_to :user

end

