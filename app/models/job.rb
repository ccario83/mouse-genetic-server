class Job < ActiveRecord::Base
	attr_accessible :creator, :groups, :directory, :name, :description, :datafile, :state, :runner, :parameters 
	before_create :create_job_directory
	before_create :default_values

	
	belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id'
	belongs_to :datafile
	has_and_belongs_to_many :groups
	
	validates :creator,	:presence => true
	validates :runner,	:presence => true, :inclusion => { :in => ['UWF'], :message => "Invalid job type" }
	validates_associated :datafile
		
	private
		def create_job_directory
			# Create a subdirectory that is a combination of the user name alpha characters and a small hex key
			subdir = self.runner.downcase + '.' + SecureRandom.hex(3)
			# Try to create a directory for this job using the id as a directory name
			directory = File.join(self.creator.directory, subdir)
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
end
