class TestName < ActiveRecord::Base
  establish_connection Rails.configuration.database_configuration["phenotype"]

  has_many :special_tests
  
end
