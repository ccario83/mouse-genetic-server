class Diagnosis < ActiveRecord::Base
  # attr_accessible :title, :body
  establish_connection Rails.configuration.database_configuration["phenotype"]
  set_table_name "Diagnosis"
  set_primary_key "_diagnosis_key"
  # If you need to alias a table field for ruby: goes 'ruby_alias, table_field'
  #alias_attribute "name", "person_name"
  
  belongs_to :Mouse
  belongs_to :PathBaseTerm
  belongs_to :MouseAnatomyTerm
  belongs_to :DiseaseDescTerm
  
end
