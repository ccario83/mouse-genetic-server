class Resource < ActiveRecord::Base
    attr_accessible :name, :address, :latitude, :longitude, :description, :owner, :website, :resource, :resource_type_ids
    has_and_belongs_to_many :resource_types
    
    acts_as_gmappable :latitude => 'latitude', :longitude => 'longitude', :process_geocoding => :geocode?,
                      :address => "", :normalized_address => "",
                      :msg => "Sorry, not even Google could figure out where that is"

    def geocode?
      (latitude.blank? || longitude.blank?)
    end
    
    def gmaps4rails_infowindow
      "<dl class='dl-horizontal'>
           <dt>Resource</dt><dd>#{name}</dd>
           <dt>Department</dt><dd>#{address}</dd>
           <dt>Owner</dt><dd>#{owner}</dd>
           <dt>Website</dt><dd><a href=#{website}>Click here</a></dd>
        </dl>
      "
    end
end
