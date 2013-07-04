class Datafile < ActiveRecord::Base
	attr_accessible :owner, :filename, :description, :directory, :uwf_runnable
	before_create :create_data_directory, :check_uwf_compatibility
	before_save :verify_quota   # See below
	after_destroy :remove_file  # See below
	
	belongs_to :owner, :class_name => 'User', :foreign_key => 'owner_id'
	has_and_belongs_to_many :groups
	has_many :jobs, :dependent => :destroy

	validates :owner, :presence => true
	validates :filename, :presence => true

	# Set the default number of posts per page for will_paginate
	self.per_page = 4

	# A really simple to string function
	def to_s
		s = "#{self.filename} - #{self.description}"
		s = s.length > 18? s[0..15]+'...' : s 
		return s
	end

	# Abstracts creating a filehandle of the file so a user can just read/write to the object... really not necessary, just a convenience function
	def get_filehandle(flag)
		return File.open(self.get_path, flag)
	end
	
	# This function writes uploaded file data to a local file (in the user's data directory)
	def process_uploaded_file(source)
		# Verify the source isn't empty
		if source == '' or source.nil?
			self.errors[:filename] << "A file must be present."
			return
		end
		
		# Verify the source filename has a legal list of characters
		if not source.original_filename.match(/ ^.*\/(.[^\/`"':]+)$/).nil?
			self.errors[:base] << "The uploaded file name cannot contain /, \", `, :, or \' characters."
			return
		end
		
		# Use the same filename as the one the user uploaded and put it in the user's data subdirectory
		self.filename = source.original_filename
		self.directory = File.join(self.owner.directory,'data')
		
		# Open the file and write to it. Return the path when finished
		File.open(self.get_path, "wb") { |f| f.write(source.read) }
		return self.get_path
	end
	
	# Processing a local file is as easy as copying it to the user's data directory
	def process_local_file(source)
		self.filename = File.basename(source)
		self.directory = File.join(self.owner.directory, 'data')
		FileUtils.cp source, self.directory
		return self.get_path
	end
	
	# Returns the full path (directory + filename) of the file (or creates a data directory if one isn't present for this user)
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
	
	def download_link
		return File.join('/data', self.get_path.split(USER_DATA_PATH)[1])
	end
	
	
	private
		# Simple function to make sure the user isn't using too much disk space
		def verify_quota
			if self.owner.used_quota?
				self.errors[:base] << 'You have reached your maximum disk quota.'
			end
		end
		
		# Simple function to create a data subdirectory in the user's folder if one doesn't exist
		def create_data_directory
			self.directory = File.join(self.owner.directory, 'data') unless not self.directory.nil?
		end
		
		# This function verifies the uploaded file as being in the proper format for the UWF tool
		def check_uwf_compatibility
			require 'csv'
			uwf_header = ["Strain", "Animal_Id", "Sex"]

			# Get the file contents (should be tab delimited)
			contents = CSV.read(self.get_path, :headers => true, :quote_char => '"', :col_sep =>"\t", :row_sep =>:auto)
			# Make sure there are 4 columns, and that the 3 required (above) are present
			if contents.headers.length != 4
				return
			elsif (uwf_header.map {|x| x.downcase} != contents.headers.slice(0,3).map{|x| x.downcase})
				return
			end
			contents.each do |entry|
				# Verify strain contains any letter, number, underscore, <, >, +, or / character
				if (entry[contents.headers[0]] =~ /^[\w\/\+<>\-\. ]+$/).nil?
					puts "Bad strain" 
					return
				# Verify the second ID column is alpha numeric word
				elsif (entry[contents.headers[1]] =~ /^\w+$/).nil?
					puts "Bad id" 
					return
				# Verify sex is male, female, na, or both 
				elsif (entry[contents.headers[2]] =~ /^(male|m|female|f|na|n\/a|both){1}$/i).nil?
					puts "Bad sex"
					return
				# Verify numeric phenotype
				elsif (entry[contents.headers[3]] =~ /^-?(\d|\.)+\d*$/).nil?
					puts "Bad phenotype"
					return
				end
				
				# Clean up sex column
				if !(entry[contents.headers[2]] =~ /^(male|m)$/i).nil?
					entry[contents.headers[2]]= 'male'
				elsif !(entry[contents.headers[2]] =~ /^(female|f)$/i).nil?
					entry[contents.headers[2]]= 'female'
				elsif !(entry[contents.headers[2]] =~ /^(na|n\/a)$/i).nil?
					entry[contents.headers[2]]= 'na'
				end
				
			end
			# Write cleaned up version
			File.open(self.get_path, 'w') do |f|
				uwf_header.each {|e| f.write e + "\t"}
				f.write contents.headers[3] + "\n"
				contents.each {|e| f.write e.to_s.gsub(",","\t") }
			end
			# If the file has made it this far, it can be run with UWF, set the flag to true
			self.uwf_runnable = true
			return
		end
		
		# Uses fileutils to remove the datafile
		def remove_file
			require 'fileutils'
			# Delete all files in this job directory
			#Dir["#{self.directory}/**/*"].each{ |file| File.delete(file) if File.file? file }
			#Dir["#{self.directory}/**/*/"].each{ |dir| Dir.delete(dir) }
			#Dir.delete(self.directory)
			FileUtils.rm_rf self.get_path
			# Delete redis key? (Below doens't work)
			#$redis.del "#{self.creator.redis_key}:#{self.redis_key}:*"
		end
		
end
