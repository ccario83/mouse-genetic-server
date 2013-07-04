class Job < ActiveRecord::Base
	attr_accessible :creator, :groups, :directory, :name, :description, :datafile, :resultfile, :state, :runner, :parameters 
	before_create :create_job_directory
	after_initialize :default_values
	before_save :ensure_paramaters_are_JSON
	after_destroy :remove_files
	
	belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id'
	belongs_to :datafile
	has_and_belongs_to_many :groups
	
	validates :name, :presence => true
	validates :creator,	:presence => true
	validates :runner,	:presence => true, :inclusion => { :in => ['UWF', 'Circos', 'BULK', 'reports'], :message => "Invalid job type" }
	validates :state, :inclusion => { :in => ['Starting', 'Progressing', 'Completed', 'Failed'], :message => "Invalid job state" }
	validates :datafile, :presence => true
	validates_associated :datafile
	
	# Set the default number of posts per page for will_paginate
	self.per_page = 4
	
	# The job's redis key is the final 'job.[hex_key]' subdirectory
	def redis_key
		return self.directory.split(/^.*\/([\.a-zA-Z0-9]+)$/)[1]
	end
	
	# Returns the value of a key 'parameter' in the job parameter list (is stored as JSON string in database)
	def get_parameter(parameter)
		return JSON.parse(self.parameters)[parameter]
	end
	
	# Return all parameters as a hash (key: value pairs)
	def get_parameters()
		return JSON.parse(self.parameters)
	end
	
	# Stores a parameter. 'parameter' is a key:value hash like {animal: 'dog'}
	def store_parameter(parameter)
		store_parameters(parameter)
	end
	
	# Stores the key:value pairs of a list of parameters (sent as a hash like {animal: 'dog' age: 4, color: 'brown'}) in the job parameter list (a JSON string in the database)
	def store_parameters(parameters)
		# Decode JSON string, add each key:value pair, reencode/save JSON string
		self.parameters = JSON.parse(self.parameters)
		parameters.each {|key,value| self.parameters[key] = value }
		self.parameters = self.parameters.to_json
	end
	
	# Remove a parameter from the job parameter list
	def delete_parameter(parameter_key)
		# Decode JSON string, remove key, reencode/save JSON string
		self.parameters = JSON.parse(self.parameters)
		parameters.delete(parameter_key)
		self.parameters = self.parameters.to_json
	end
	
	# Generates a URL that rails recognizes and will serve user job content with (NOT REALLY USED)
	def download_link
		return File.join('/data', self.directory.split(USER_DATA_PATH)[1])
	end
	
	# Report the progress of the job as a rough percentage. Returns a flow between 0.0 and 100.00 or nil
	def progress
		if self.state  == 'Completed'
			return 100.0
		end
		begin
			if $redis.exists "#{self.creator.redis_key}:#{self.redis_key}:progress:log"
				return ($redis.scard "#{self.creator.redis_key}:#{self.redis_key}:progress:log")/15.0*100
			else
				return nil
			end
		rescue
			return nil
		end
	end
	
	# Returns a list of errors reported through redis by any of the job's sub-scripts
	def runtime_errors
		error_log = []
		begin
			if $redis.exists "#{self.creator.redis_key}:#{self.redis_key}:error:log"
				error_log = $redis.smembers "#{self.creator.redis_key}:#{self.redis_key}:error:log"
			end
		rescue
			return nil
		end
		return error_log
	end
	
	private
		# Creates a job directory
		def create_job_directory
			# Create a subdirectory that is a combination of the user name alpha characters and a small hex key
			subdir = self.runner.downcase + '.' + SecureRandom.hex(3)
			# Try to create a directory for this job using the id as a directory name
			directory = File.join(self.creator.directory, 'jobs', subdir)
			begin
				Dir.mkdir(directory) unless File.directory?(directory)
			rescue
				errors.add_to_base('There was an issue creating this user account. Please contact the web administrator.')
			end
			self.directory = directory
		end
		
		# A job when created is has a starting state by default
		def default_values
			self.state ||= 'Starting'
		end
		
		# A simple check to make sure the parameter list is JSON parse-able 
		def ensure_paramaters_are_JSON()
			begin
				JSON.parse(self.parameters)
				return
			rescue
				self.parameters = self.parameters.to_json
			end
		end
		
		# Use fileutils to remove all job associated files
		def remove_files
			require 'fileutils'
			# Delete all files in this job directory
			#Dir["#{self.directory}/**/*"].each{ |file| File.delete(file) if File.file? file }
			#Dir["#{self.directory}/**/*/"].each{ |dir| Dir.delete(dir) }
			#Dir.delete(self.directory)
			FileUtils.rm_rf self.directory
			# Delete redis key? (Below doens't work)
			#$redis.del "#{self.creator.redis_key}:#{self.redis_key}:*"
		end
end
