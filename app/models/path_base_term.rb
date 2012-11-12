class PathBaseTerm < ActiveRecord::Base
  establish_connection Rails.configuration.database_configuration["phenotype"]

  has_many :diagnoses
end
