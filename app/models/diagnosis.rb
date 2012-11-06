class Diagnosis < ActiveRecord::Base
  # attr_accessible :title, :body
  establish_connection Rails.configuration.database_configuration["phenotype"]
  
  belongs_to :mouse
  belongs_to :path_base_term
  belongs_to :mouse_anatomy_term
  belongs_to :disease_desc_term
  
end
