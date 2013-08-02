class Micropost < ActiveRecord::Base
	attr_accessible :creator, :content, :group_recipients, :user_recipients, :recipient_type
	# Some of the views like to know if the micropost was communicated to a user, group, or both for styling reasons. Set this parameter before save
	before_save :set_recipient_type 

	# A micropost belongs to the user that created it 
	belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id'

	# A micropost has many polymorphic communication relationships which should be destroyed with the micropost
	has_many :communications, :dependent => :destroy
	# A polymorphic has_many :through relationship
	#    :user_recipients is the association name 
	#    :through indicates the Model name of the join table
	#    :source indicates the column in that table that contains the ids (user or group), resolves to recipient_id
	#    :source_type indicates the connected model (user or group), which is represented as a string in a column recipient_type
	# A model must be generated like: rails g model Communication :recipient_id:integer :recipient_type:string micropost_id:integer
	# A table should also be created matching through a migration
	has_many :group_recipients, :through => :communications, :class_name => 'Group', :source => :recipient, :source_type => 'Group'
	has_many :user_recipients,  :through => :communications, :class_name => 'User',  :source => :recipient, :source_type => 'User', :validate => false # Don't know why this needs to be false, but it won't work otherwise

	validates :creator_id, :presence => true
	validates :content, :presence => true, :length => { :minimum => 1, :maximum => 255 }
	validate :recipient_presence
	validate :creator_is_in_system, :on => :create

	default_scope :order => 'microposts.created_at DESC'

	# Set the default number of posts per page for will_paginate
	self.per_page = 4

	private
		# Make sure there is at least one recipient 
		def recipient_presence
			if self.user_recipients.empty? && self.group_recipients.empty?
				errors.add(:user_recipients, "Please specify at least one group or user recipient")
			end
		end

		# Set the recipient type (User,group, or both)
		def set_recipient_type
			if self.user_recipients.empty?
				self.recipient_type = 'Group'
			elsif self.group_recipients.empty?
				self.recipient_type = 'User'
			else
				self.recipient_type = 'Both'
			end
		end

		def creator_is_in_system
			creator_ids = User.all.map{|u| u.id}
			unless creator_ids.include?(self.creator_id)
				errors.add(:user, "is not in the system")
			end
		end
end

