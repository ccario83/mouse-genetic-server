class Communication < ActiveRecord::Base
  attr_accessible :micropost_id, :recipient_id, :recipient_type
  
  belongs_to :recipient, :polymorphic => true
  belongs_to :micropost
end
