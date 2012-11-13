#===============================================================================
# Programmer:	Clinton Cario
# Purpose:	This gem is a rewrite of the python jobber module
#
# Modification History:
#  2012 01 19 -- Version 1.0 Django Version
#  2012 08 24 -- Version 1.0 Ruby Version
#===============================================================================
require 'securerandom'
# Set some paths
FILE_UPLOAD_ROOT = '../data/'
DATA_URL = '/data/'

class Job
    attr_accessor :ID, :location, :type, :tracked_vars

    # Whenever a new job is initalized, we need to create a directory for it
    # We use a 6 character hex key for job ids and directory names
    def initialize(type)
        # Get a new id
        @ID = SecureRandom.hex(3)
        # Try to create a directory for this job using the id as a directory name
        @location = File.join(FILE_UPLOAD_ROOT, @ID)
        begin
            Dir.mkdir(@location) unless File.directory?(@location)
        rescue
            puts "There was an issue creating a new job"
        end
        @type = type
        @tracked_vars = {}
    end

    # This function writes uploaded file data to a file in the job directory
    def process_uploaded_file(source)
        @name = File.join(@location, source.original_filename)
        File.open(@name, "wb") { |f| f.write(source.read) }
        return @name
    end

    # This function adds to a list the name of variable whose value should be tracked (saved to a pickle file for later retrieval)
    # Send the name as a string. This only keeps track of which variables should be saved!
    # Actual values are saved only when the save() function is called
    def track_var(var, bind)
        @tracked_vars.merge!({var => eval(var, bind) })
    end

    # Removes a variable name from a list of tracked variables
    def untrack_var(var)
        @tracked_vars.delete(var)
    end

    # This function gets the full path of a requested file, otherwise return nil (ie. the file doesn't exist)
    def get_path(requested_file)
        if FileTest.exists?(File.join(@location, requested_file))
            return File.join(@location, requested_file)
        else
            return nil
        end
    end

    # This function is depreciated but creates a URL where a file can be accessed by apache
    def make_weblink(requested_file)
        if FileTest.exists?(File.join(@location, requested_file))
            return File.join(DATA_URL, @ID, requested_file)
        else
            return nil
        end
    end

    # This function serializes the variables that were requested to be tracked and saves them as a pickled file called pickle.jar, using the Marshal gem
    def save()
        #serialization
        File.open(File.join(@location, "pickle.jar"),"wb") do |file|
            Marshal.dump(self, file)
        end
    end
end


# This function will deserialize data from the pickle jar given a job id, and returns the job
def restore_job(job_ID)
    #de-serialization
    File.open(File.join(FILE_UPLOAD_ROOT, job_ID, "pickle.jar"),"rb") do |file|
        @job = Marshal.load(file)
    end
    return @job
end
