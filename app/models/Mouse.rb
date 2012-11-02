class Mouse < ActiveRecord::Base

  establish_connection Rails.configuration.database_configuration["phenotype"]
  set_table_name "Mouse"
  set_primary_key "_mouse_key"
  # If you need to alias a table field for ruby: goes 'ruby_alias, table_field'
  #alias_attribute "name", "person_name"

  has_many :Diagnosis
  has_many :SpecialTest
  has_one :Detail
  
end
