class Mouse < ActiveRecord::Base
  # attr_accessible :title, :body
  has_many :Diagnosis
  has_many :SpecialTest
  has_one :Detail
  
end
