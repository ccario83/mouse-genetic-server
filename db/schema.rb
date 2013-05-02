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

ActiveRecord::Schema.define(:version => 20130502175616) do

  create_table "communications", :force => true do |t|
    t.integer "recipient_id"
    t.string  "recipient_type"
    t.integer "micropost_id"
  end

  create_table "datafiles", :force => true do |t|
    t.integer  "owner_id"
    t.string   "filename"
    t.text     "description"
    t.string   "directory"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.boolean  "uwf_runnable", :default => false
  end

  add_index "datafiles", ["owner_id"], :name => "index_datafiles_on_owner_id"

  create_table "datafiles_groups", :id => false, :force => true do |t|
    t.integer "datafile_id"
    t.integer "group_id"
  end

  add_index "datafiles_groups", ["datafile_id", "group_id"], :name => "index_datafiles_groups_on_datafile_id_and_group_id", :unique => true

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "creator_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "groups_jobs", :id => false, :force => true do |t|
    t.integer "group_id"
    t.integer "job_id"
  end

  add_index "groups_jobs", ["group_id", "job_id"], :name => "index_groups_jobs_on_group_id_and_job_id", :unique => true

  create_table "jobs", :force => true do |t|
    t.integer  "creator_id"
    t.integer  "datafile_id"
    t.string   "directory"
    t.string   "name"
    t.text     "description"
    t.string   "state"
    t.string   "runner"
    t.text     "parameters"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "jobs", ["creator_id"], :name => "index_jobs_on_creator_id"

  create_table "memberships", :force => true do |t|
    t.integer "group_id"
    t.integer "user_id"
    t.boolean "confirmed", :default => false
  end

  add_index "memberships", ["group_id", "user_id"], :name => "index_groups_users_on_group_id_and_user_id", :unique => true

  create_table "microposts", :force => true do |t|
    t.string   "content"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.integer  "creator_id"
    t.string   "recipient_type"
  end

  add_index "microposts", ["recipient_type", "created_at"], :name => "index_microposts_on_recipient"

  create_table "recipients", :force => true do |t|
    t.integer  "recipient_id"
    t.string   "recipient_type"
    t.integer  "micropost_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  create_table "resources", :force => true do |t|
    t.string   "resource_type"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "sequencers", :force => true do |t|
    t.string   "name"
    t.string   "address"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "description"
    t.integer  "owner"
    t.string   "website"
    t.string   "type"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "tags", :force => true do |t|
    t.string   "resource_type"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "tasks", :force => true do |t|
    t.string   "description"
    t.integer  "group_id"
    t.integer  "creator_id"
    t.integer  "assignee_id"
    t.boolean  "completed",   :default => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.datetime "due_date"
  end

  create_table "users", :force => true do |t|
    t.string   "first_name"
    t.string   "email"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.string   "password_digest"
    t.string   "remember_token"
    t.boolean  "admin",           :default => false
    t.string   "last_name"
    t.string   "institution"
    t.string   "directory"
  end

  add_index "users", ["directory"], :name => "index_users_on_directory"
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["remember_token"], :name => "index_users_on_remember_token"

end
