class Mouse < ActiveRecord::Base

  establish_connection Rails.configuration.database_configuration["phenotype"]

  has_many :diagnoses
  has_many :special_tests
  belongs_to :strain

end
