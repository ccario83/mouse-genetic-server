class PathBaseTerms < ActiveRecord::Base
  establish_connection Rails.configuration.database_configuration["phenotype"]
  set_table_name "PathBaseTerm"
  set_primary_key "_mpath_key"
  # If you need to alias a table field for ruby: goes 'ruby_alias, table_field'
  #alias_attribute "name", "person_name"
  # attr_accessible :title, :body
  has_many :Diagnosis
end
