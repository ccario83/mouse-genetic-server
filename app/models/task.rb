class Task < ActiveRecord::Base

	attr_accessible :creator, :group, :assignee, :description, :due_date, :completed, :group_id, :creator_id, :assignee_id
	
	# A task belongs to a group
	belongs_to :group, :class_name => 'Group', :foreign_key => 'group_id'
	belongs_to :assignee, :class_name => 'User', :foreign_key => 'assignee_id'
	belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id'


	validates :creator, :presence => true
	validates :assignee, :presence => { :message => "A task must have an assignee."}
	validates :due_date, :presence => true
	validates :description, :presence => true, :length => { :minimum => 1, :maximum => 140 }

	default_scope :order => 'tasks.created_at DESC'

	# Set the default number of posts per page for will_paginate
	self.per_page = 4
	
end
