class Datafile < ActiveRecord::Base
	attr_accessible :owner, :filename, :description, :directory, :uwf_runnable
	before_create :create_data_directory
	before_save :verify_quota
	
	belongs_to :owner, :class_name => 'User', :foreign_key => 'owner_id'
	has_and_belongs_to_many :groups

	validates :owner, :presence => true
	validates :filename, :presence => true

	def get_filehandle(flag)
		return File.open(self.get_path, flag)
	end
	
	# This function writes uploaded file data to a file in the job directory
	def process_uploaded_file(source)
		if source.original_filename.match(/ ^.*\/(.[^\/`"':]+)$/).nil?
			self.errors[:base] << "The uploaded file name cannot contain /, \", `, :, or \' characters."
			return
		end
		
		# Set the filename
		self.filename = source.original_filename
		self.directory = File.join(self.owner.directory,' data')
		
		File.open(self.get_path, "wb") { |f| f.write(source.read) }
		return self.get_path
	end
	
	def get_path
		if self.directory.nil?
			create_data_directory
		end
		if self.filename.nil?
			self.errors[:filename] << "You must specify a filename before a path can be generated."
			return
		end
		return File.join(self.directory,self.filename)
	end
	
	private
	
		def verify_quota
			if self.owner.used_quota?
				self.errors[:base] << 'You have reached your maximum disk quota.'
			end
		end
	
		def create_data_directory
			self.directory = File.join(self.owner.directory, 'data') unless not self.directory.nil?
		end

end
