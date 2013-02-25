class Micropost < ActiveRecord::Base
	attr_accessible :creator_id, :recipient_id, :recipient_type, :content
	
	# A micropost belongs to the user that created it 
	belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id'
	
	# A micropost also belongs to the intended recipient, which can be either another user or a group	
	belongs_to :recipient, :polymorphic => true

	validates :creator_id, :presence => true
	validates :recipient_id, :presence => true
	validates :recipient_type, :presence => true
	validates :content, :presence => true, :length => { :minimum => 1, :maximum => 140 }

	default_scope :order => 'microposts.created_at DESC'

	# Set the default number of posts per page for will_paginate
	self.per_page = 4
end
