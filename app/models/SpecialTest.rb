class SpecialTest < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :Mouse
  belongs_to :TestName
  
end
