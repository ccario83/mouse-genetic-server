class Micropost < ActiveRecord::Base
	attr_accessible :content
	belongs_to :user

	validates :user_id, :presence => true
	validates :content, :presence => true, :length => { :minimum => 1, :maximum => 140 }

	default_scope :order => 'microposts.created_at DESC'

	# Set the number of posts per page for will_paginate
	self.per_page = 5
end
