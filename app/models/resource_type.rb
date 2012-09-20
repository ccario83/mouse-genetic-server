class ResourceType < ActiveRecord::Base
  attr_accessible :resource_type
  has_and_belongs_to_many :resources
end
