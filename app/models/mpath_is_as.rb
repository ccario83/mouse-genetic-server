class MpathIsA < ActiveRecord::Base

  establish_connection Rails.configuration.database_configuration["phenotype"]


end
