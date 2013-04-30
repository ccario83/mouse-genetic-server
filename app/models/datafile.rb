class Datafile < ActiveRecord::Base
	attr_accessible :owner, :filename, :description, :directory, :uwf_runnable
	before_create :create_data_directory
	before_save :verify_quota, :check_uwf_compatibility
	
	belongs_to :owner, :class_name => 'User', :foreign_key => 'owner_id'
	has_and_belongs_to_many :groups

	validates :owner, :presence => true
	validates :filename, :presence => true

	# Set the default number of posts per page for will_paginate
	self.per_page = 4

	def get_filehandle(flag)
		return File.open(self.get_path, flag)
	end
	
	# This function writes uploaded file data to a file in the job directory
	def process_uploaded_file(source)
		if not source.original_filename.match(/ ^.*\/(.[^\/`"':]+)$/).nil?
			self.errors[:base] << "The uploaded file name cannot contain /, \", `, :, or \' characters."
			return
		end
		
		# Set the filename
		self.filename = source.original_filename
		self.directory = File.join(self.owner.directory,'data')
		
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
		
		def check_uwf_compatibility
			require 'csv'
			uwf_header = ["Strain", "Animal_Id", "Sex"]

			contents = CSV.read(self.get_path, :headers => true, :quote_char => '"', :col_sep =>"\t", :row_sep =>:auto)
			if contents.headers.length < 4
				return
			elsif (uwf_header.map {|x| x.downcase} != contents.headers.slice(0,3).map{|x| x.downcase})
				return
			end
			contents.each do |entry|
				# Verify strain contains any letter, number, underscore, <, >, +, or / character
				if (entry[contents.headers[0]] =~ /^[\w\/\+<> ]+$/).nil?
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
				f.write uwf_header << contents.headers[3]
				contents.each {|e| f.write e.to_s.gsub(',','\t') }
			end

			self.uwf_runnable = true
			return
		end
end
