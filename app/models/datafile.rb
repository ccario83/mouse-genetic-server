class Datafile < ActiveRecord::Base
	attr_accessible :owner, :filename, :description, :directory
	before_create :create_file
	before_save :verify_quota
	
	belongs_to :owner, :class_name => 'User', :foreign_key => 'owner_id'
	has_and_belongs_to_many :groups

	validates :,	:presence => true

	def get_filehandle(flag)
		File.open(@pheno_file, flag)
	end
	
	# This function writes uploaded file data to a file in the job directory
	def process_uploaded_file(source)
		@name = File.join(@location, source.original_filename)
		File.open(@name, "wb") { |f| f.write(source.read) }
		return @name
	end
	

	
	private
	
		def verify_quota
			if self.owner.used_quota?
				errors.add_to_base('You have reached your maximum disk quota.')
			end
		end
	
		def create_file
			####### Sanitize ########
			# Split the name when finding a period which is preceded by some
			# character, and is followed by some character other than a period,
			# if there is no following period that is followed by something
			# other than a period 
			fn = filename.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m

			# We now have one or two parts (depending on whether we could find
			# a suitable period). For each of these parts, replace any unwanted
			# sequence of characters with an underscore
			fn.map! { |s| s.gsub /[^a-z0-9\-]+/i, '_' }

			# Finally, join the parts with a period and return the result
			return fn.join '.'
			
			subdir = self.filename.downcase.gsub(/[^a-z1-9]/, '') + '.' + SecureRandom.hex(3)
			# Try to create a directory for this job using the id as a directory name
			directory = File.join(USER_DATA_path, subdir)
			begin
				Dir.mkdir(directory) unless File.directory?(directory)
			rescue
				errors.add_to_base('There was an issue creating this user account. Please contact the web administrator.')
			end
			self.directory = directory
		end

end
