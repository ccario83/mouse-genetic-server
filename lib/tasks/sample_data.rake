namespace :db do 
	desc "Fill database with sample data"
	task :populate => :environment do
		admin = User.create!(:first_name 			=> "Clint",
							 :last_name				=> "Cario",
							 :institution			=> "University of Pittsburgh",
					 		 :email 				=> "clint.cario@gmail.com",
					 		 :password 				=> "foobar",
					 		 :password_confirmation => "foobar")
		admin.toggle!(:admin)
		99.times do |n|
			first_name	= Faker::Name.name.split()[0]
			last_name 	= Faker::Name.name.split()[1]
			institution = "Some Other Place"
			email		= "example-#{n+1}@otherplace.org"
			password	= "password"
			User.create!(:first_name 				=> first_name, 
						 :last_name 				=> last_name, 
						 :email 					=> email,
						 :institution				=> institution,
						 :password 					=> password, 
						 :password_confirmation 	=> password)
		end

		users = User.all(:limit => 6)
		50.times do
			content = Faker::Lorem.sentence(5)
			users.each { |user| user.microposts.create!(:content => content) }
		end
	end
end

