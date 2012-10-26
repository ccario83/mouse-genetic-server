# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120919190136) do

  create_table "resource_types", :force => true do |t|
    t.string "name", :limit => 64, :null => false
  end

  create_table "resource_types_resources", :id => false, :force => true do |t|
    t.integer "resource_id",      :null => false
    t.integer "resource_type_id", :null => false
  end

  create_table "resources", :force => true do |t|
    t.string   "name",        :limit => 64
    t.string   "address"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "description"
    t.string   "owner",       :limit => 64
    t.string   "website"
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
    t.binary   "validated",   :limit => 1,  :default => "0"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end
  
  create_table "Diagnosis", :primary_key => "_diagnosis_key", :force => true do |t|
    t.integer "_mouse_key",                                  :null => false
    t.float   "DXORDER",                    :default => 0.0, :null => false
    t.string  "ORGAN",       :limit => 115
    t.string  "DX",          :limit => 120,                  :null => false
    t.string  "DiseaseDesc", :limit => 110
    t.string  "Score",       :limit => 2
    t.integer "NECROP_YR"
    t.integer "SPEC_NO"
  end

  add_index "Diagnosis", ["DiseaseDesc"], :name => "DiseaseDesc"
  add_index "Diagnosis", ["NECROP_YR"], :name => "NECROP_YR"
  add_index "Diagnosis", ["SPEC_NO"], :name => "SPEC_NO"
  add_index "Diagnosis", ["_diagnosis_key"], :name => "_diagnosis_key", :unique => true
  add_index "Diagnosis", ["_mouse_key"], :name => "_mouse_key"

  create_table "DiseaseDescTerms", :primary_key => "_DiseaseDesc_key", :force => true do |t|
    t.string "DiseaseDescription", :limit => 100,        :null => false
    t.string "DiseaseDescCode",    :limit => 9,          :null => false
    t.string "DiseaseDescTerm",    :limit => 110
    t.text   "Comments",           :limit => 2147483647
  end

  add_index "DiseaseDescTerms", ["DiseaseDescCode"], :name => "DiseaseDescCode", :unique => true
  add_index "DiseaseDescTerms", ["DiseaseDescription"], :name => "DiseaseDescription", :unique => true
  add_index "DiseaseDescTerms", ["_DiseaseDesc_key"], :name => "_DiseaseDesc_key"

  create_table "Mouse", :primary_key => "_mouse_key", :force => true do |t|
    t.integer  "NECROP_YR",                                              :null => false
    t.integer  "SPEC_NO",                                                :null => false
    t.string   "SCIENTIST",     :limit => 30,                            :null => false
    t.string   "BUILDING",      :limit => 3
    t.string   "ROOM",          :limit => 4
    t.datetime "SUBM_DATE",                                              :null => false
    t.string   "STRAIN",        :limit => 120
    t.string   "GENOTYPE",      :limit => 30
    t.integer  "NUMB_ANIM",                           :default => 1
    t.string   "PEDIGREENO",    :limit => 25
    t.string   "SIRE_PEDIGREE", :limit => 25
    t.string   "DAM1_PEDIGREE", :limit => 25
    t.string   "DAM2_PEDIGREE", :limit => 25
    t.string   "OTHERID",       :limit => 30
    t.string   "SEX",           :limit => 1
    t.string   "CODE",          :limit => 4
    t.string   "CLINIC_NO",     :limit => 7
    t.datetime "DATE_BORN"
    t.string   "MATING",        :limit => 1
    t.boolean  "COLORPHOTO",                          :default => false
    t.boolean  "BW_PHOTO",                            :default => false
    t.boolean  "MICROPHOTO",                          :default => false
    t.boolean  "FROZENTISS",                          :default => false
    t.boolean  "HISTOLOGY",                           :default => false
    t.boolean  "XRAY",                                :default => false
    t.boolean  "SEM",                                 :default => false
    t.boolean  "INSITU",                              :default => false
    t.boolean  "WAX_BLOCK",                           :default => false
    t.boolean  "WET_TISSUE",                          :default => false
    t.boolean  "CLINPATH",                            :default => false
    t.boolean  "RNA",                                 :default => false
    t.string   "SOURCE",        :limit => 2
    t.string   "CATEGORY",      :limit => 3
    t.text     "GROSSDESC",     :limit => 2147483647
    t.text     "DIAG_MEMO",     :limit => 2147483647
    t.string   "PATHOLOGIS",    :limit => 3
    t.datetime "PRE_DATE"
    t.datetime "TEL_DATE"
    t.datetime "FINAL_DATE"
    t.string   "DX_1",          :limit => 66
    t.string   "DX_2",          :limit => 66
    t.string   "DX_3",          :limit => 66
    t.string   "DX_4",          :limit => 66
    t.string   "DX_5",          :limit => 66
    t.string   "DX_6",          :limit => 66
    t.string   "DX_7",          :limit => 66
    t.string   "LINE_NUM",      :limit => 8
    t.string   "CONSTRUCT",     :limit => 64
    t.integer  "JR_NUM"
  end

  add_index "Mouse", ["BUILDING", "ROOM"], :name => "BUILDING"
  add_index "Mouse", ["CLINIC_NO"], :name => "CLINIC_NO"
  add_index "Mouse", ["CODE"], :name => "CODE"
  add_index "Mouse", ["GENOTYPE"], :name => "GENOTYPE"
  add_index "Mouse", ["JR_NUM"], :name => "JR_NUM"
  add_index "Mouse", ["LINE_NUM"], :name => "LINE_NUM"
  add_index "Mouse", ["NECROP_YR", "SPEC_NO"], :name => "NECROP_YR", :unique => true
  add_index "Mouse", ["NECROP_YR"], :name => "NECROP_YR_2"
  add_index "Mouse", ["NUMB_ANIM"], :name => "NUMB_ANIM"
  add_index "Mouse", ["OTHERID"], :name => "OTHERID"
  add_index "Mouse", ["SCIENTIST"], :name => "SCIENTIST"
  add_index "Mouse", ["SPEC_NO"], :name => "SPEC_NO"
  add_index "Mouse", ["STRAIN"], :name => "STRAIN"
  add_index "Mouse", ["SUBM_DATE", "STRAIN"], :name => "SUBM_DATE"
  add_index "Mouse", ["SUBM_DATE"], :name => "SUBM_DATE_2"
  add_index "Mouse", ["_mouse_key"], :name => "_mouse_key", :unique => true

  create_table "MouseAnatomyTerms", :primary_key => "_MA_key", :force => true do |t|
    t.string "MA_termName", :limit => 100
    t.string "accessionID", :limit => 10
    t.string "synonyms",    :limit => 100
    t.string "FullMAterm",  :limit => 115
  end

  add_index "MouseAnatomyTerms", ["MA_termName"], :name => "MA_termName", :unique => true
  add_index "MouseAnatomyTerms", ["accessionID"], :name => "accessionID", :unique => true

  create_table "Name", :primary_key => "_test_key", :force => true do |t|
    t.string "TEST",      :limit => 8,  :null => false
    t.string "TESTDESC",  :limit => 60, :null => false
    t.float  "UNITPRICE"
  end

  add_index "Name", ["TEST"], :name => "TEST", :unique => true
  add_index "Name", ["_test_key"], :name => "_test_key", :unique => true

  create_table "PathBaseTerms", :primary_key => "ID", :force => true do |t|
    t.string "term",                                      :null => false
    t.string "pathBaseNumber",      :limit => 64,         :null => false
    t.string "photo_needed",        :limit => 16
    t.text   "definition",          :limit => 2147483647
    t.text   "definitionReference", :limit => 2147483647
    t.text   "comments",            :limit => 2147483647
    t.string "term_and_MPATH"
  end

  add_index "PathBaseTerms", ["pathBaseNumber"], :name => "pathBaseNumber", :unique => true
  add_index "PathBaseTerms", ["term"], :name => "term", :unique => true

  create_table "SpecialTest", :primary_key => "_specialTest_key", :force => true do |t|
    t.integer "_mouse_key",                                         :null => false
    t.integer "_test_key",                                          :null => false
    t.integer "_organism_key"
    t.string  "SEROLOGY",      :limit => 5
    t.integer "NO_POS",        :limit => 1,          :default => 0, :null => false
    t.integer "NO_NEG",        :limit => 1,          :default => 0, :null => false
    t.float   "RESULT"
    t.string  "RESULTUNITS",   :limit => 16
    t.float   "CHARGE"
    t.string  "DESC",          :limit => 30
    t.text    "TESTCOMMENT",   :limit => 2147483647
    t.integer "NECROP_YR"
    t.integer "SPEC_NO"
    t.string  "TEST",          :limit => 8
    t.string  "ORGANISM",      :limit => 4
  end

  add_index "SpecialTest", ["NECROP_YR"], :name => "NECROP_YR"
  add_index "SpecialTest", ["SPEC_NO", "TEST"], :name => "SPEC_NO"
  add_index "SpecialTest", ["SPEC_NO"], :name => "SPEC_NO_2"
  add_index "SpecialTest", ["TEST"], :name => "TEST"
  add_index "SpecialTest", ["_mouse_key"], :name => "_mouse_key"
  add_index "SpecialTest", ["_organism_key"], :name => "_organism_key"
  add_index "SpecialTest", ["_specialTest_key"], :name => "_specialTest_key", :unique => true
  add_index "SpecialTest", ["_test_key"], :name => "_test_key"

  create_table "Strains", :primary_key => "StrainName", :force => true do |t|
    t.integer "JRnum"
  end

  add_index "Strains", ["JRnum"], :name => "JRnum", :unique => true
  add_index "Strains", ["StrainName"], :name => "StrainName", :unique => true

  create_table "anat_alts", :force => true do |t|
    t.string "term_id", :limit => 16
    t.string "alt",     :limit => 16
  end

  create_table "anat_is_as", :force => true do |t|
    t.string "term_id", :limit => 16
    t.string "is_a",    :limit => 16
  end

  create_table "anat_relationships", :force => true do |t|
    t.string "type",         :limit => 16
    t.string "relationship", :limit => 16
    t.string "term_id",      :limit => 16
  end

  create_table "anat_synonyms", :force => true do |t|
    t.string "term_id", :limit => 16
    t.string "name",    :limit => 128
    t.string "type",    :limit => 16
    t.text   "tag"
  end

  create_table "anat_terms", :primary_key => "term_id", :force => true do |t|
    t.string  "name",        :limit => 128
    t.text    "def"
    t.text    "tag"
    t.text    "comment"
    t.string  "created_by",  :limit => 64
    t.date    "created_on"
    t.text    "xref"
    t.boolean "is_obsolete"
  end

  create_table "mpath_alts", :force => true do |t|
    t.string "term_id", :limit => 16
    t.string "alt",     :limit => 16
  end

  create_table "mpath_is_as", :force => true do |t|
    t.string "term_id", :limit => 16
    t.string "is_a",    :limit => 16
  end

  create_table "mpath_relationships", :force => true do |t|
    t.string "type",         :limit => 16
    t.string "relationship", :limit => 16
    t.string "term_id",      :limit => 16
  end

  create_table "mpath_synonyms", :force => true do |t|
    t.string "term_id", :limit => 16
    t.string "name",    :limit => 128
    t.string "type",    :limit => 16
    t.text   "tag"
  end

  create_table "mpath_terms", :primary_key => "term_id", :force => true do |t|
    t.string  "name",        :limit => 128
    t.text    "def"
    t.text    "tag"
    t.text    "comment"
    t.string  "created_by",  :limit => 64
    t.date    "created_on"
    t.text    "xref"
    t.boolean "is_obsolete"
  end

end
