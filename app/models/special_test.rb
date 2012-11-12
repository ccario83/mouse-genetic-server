class SpecialTest < ActiveRecord::Base
  establish_connection Rails.configuration.database_configuration["phenotype"]

  belongs_to :mouse
  belongs_to :test_name
  
end
