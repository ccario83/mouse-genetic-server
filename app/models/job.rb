class Job < ActiveRecord::Base
	attr_accessible :creator, :groups, :directory, :name, :description, :datafile, :state, :runner, :parameters 
	before_create :create_job_directory
	after_initialize :default_values
	before_save :ensure_paramaters_are_JSON
	after_destroy :remove_files
	
	belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id'
	belongs_to :datafile
	has_and_belongs_to_many :groups
	
	validates :name, :presence => true
	validates :creator,	:presence => true
	validates :runner,	:presence => true, :inclusion => { :in => ['UWF', 'BULK'], :message => "Invalid job type" }
	validates :state, :inclusion => { :in => ['Starting', 'Progressing', 'Completed', 'Failed'], :message => "Invalid job state" }
	validates :datafile, :presence => true
	validates_associated :datafile
	
	# Set the default number of posts per page for will_paginate
	self.per_page = 4
	
	def redis_key
			return self.directory.split(/^.*\/([\.a-zA-Z0-9]+)$/)[1]
	end
	
	def get_parameter(parameter)
		return JSON.parse(self.parameters)[parameter]
	end
	
	def get_parameters()
		return JSON.parse(self.parameters)
	end
	
	def store_parameter(parameter)
		store_parameters(parameter)
	end
	
	def store_parameters(parameters)
		self.parameters = JSON.parse(self.parameters)
		parameters.each {|key,value| self.parameters[key] = value }
		self.parameters = self.parameters.to_json
	end
	
	def progress
		if self.state  == 'Completed'
			return 100.0
		end
		begin
			if $redis.exists "#{self.creator.redis_key}:#{self.redis_key}:progress:log"
				return ($redis.scard "#{self.creator.redis_key}:#{self.redis_key}:progress:log")/15.0*100
			else
				if self.name == 'Starting'
					return 5
				elsif self.name == 'Progressing'
					return 68
				elsif self.name == 'Completed'
					return 100
				elsif self.name == 'Failed'
					return 25
				else
					return nil
				end
			end
		rescue
			return nil
		end
	end
	
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
		
		def default_values
			self.state ||= 'Starting'
		end
		
		def ensure_paramaters_are_JSON()
			begin
				JSON.parse(self.parameters)
				return
			rescue
				self.parameters = self.parameters.to_json
			end
		end
		
		def remove_files
			# Delete all files in this job directory
			Dir["#{self.directory}/**/*"].each{ |file| File.delete(file) if File.file? file }
			Dir["#{self.directory}/**/*/"].each{ |dir| Dir.delete(dir) }
			Dir.delete(self.directory)
			# Delete redis key?
		end
end
