class Diagnosis < ActiveRecord::Base
  # attr_accessible :title, :body
  
  belongs_to :Mouse
  belongs_to :PathBaseTerm
  belongs_to :MouseAnatomyTerm
  belongs_to :DiseaseDescTerm
  
end
