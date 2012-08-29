#===============================================================================
# Programmer:	Clinton Cario
# Purpose:	This gem is a rewrite of the python jobber module
#
# Modification History:
#  2012 01 19 -- Version 1.0 Django Version
#  2012 08 24 -- Version 1.0 Ruby Version
#===============================================================================

require 'securerandom'
FILE_UPLOAD_ROOT = '/raid/WWW/data/'
DATA_URL = '/data/'

class Job

    attr_accessor :ID, :location, :type, :tracked_vars

    def initialize(type)
        @ID = SecureRandom.hex(3)
        @location = File.join(FILE_UPLOAD_ROOT, @ID)
        begin
            Dir.mkdir(@location) unless File.directory?(@location)
        rescue
            puts "There was an issue creating a new job"
        end
        @type = type
        @tracked_vars = {}
    end


    def process_uploaded_file(source)
        @name = File.join(@location, source.original_filename)
        File.open(@name, "wb") { |f| f.write(source.read) }
        return @name
    end


    # Send the name as a string. This only keeps track of which variables should be saved!
    # Actual values are saved only when the save() function is called
    def track_var(var, bind)
        @tracked_vars.merge!({var => eval(var, bind) })
    end


    def untrack_var(var)
        @tracked_vars.delete(var)
    end


    def get_path(requested_file)
        if FileTest.exists?(File.join(@location, requested_file))
            return File.join(@location, requested_file)
        else
            return nil
        end
    end


    def make_weblink(requested_file)
        if FileTest.exists?(File.join(@location, requested_file))
            return File.join(DATA_URL, @ID, requested_file)
        else
            return nil
        end
    end


    def save()
        #serialization
        File.open(File.join(@location, "pickle.jar"),"wb") do |file|
            Marshal.dump(self, file)
        end
    end
end



def restore_job(job_ID)
    #de-serialization
    File.open(File.join(FILE_UPLOAD_ROOT, job_ID, "pickle.jar"),"rb") do |file|
        @job = Marshal.load(file)
    end
    return @job
end
