class Group < ActiveRecord::Base
  attr_accessible :description, :name
  
  # A group has a creator that is a user
  belongs_to :creator, :foreign_key => 'creator_id'
  # A group can have microposts as a micropost recipients
  has_many :microposts, :as => :recipient 
  has_and_belongs_to_many :users
  
  validates :creator_id, :presence => true
  validates :name, :presence => true
end
