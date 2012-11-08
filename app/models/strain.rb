class Strain < ActiveRecord::Base
  # attr_accessible :title, :body
  establish_connection Rails.configuration.database_configuration["phenotype"]
  
  has_many :mice

end
