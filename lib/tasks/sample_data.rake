namespace :db do 
	desc "Fill database with sample data"
	task :populate => :environment do
		make_users
		make_groups
		make_microposts
	end
end

def make_users
	admin = User.create!(:first_name 			=> "Clint",
						 :last_name				=> "Cario",
						 :institution			=> "University of Pittsburgh",
				 		 :email 				=> "clint.cario@gmail.com",
				 		 :password 				=> "foobar",
				 		 :password_confirmation => "foobar")
	admin.toggle!(:admin)
	admin = User.create!(:first_name 			=> "Annerose",
						 :last_name				=> "Berndt",
						 :institution			=> "University of Pittsburgh",
				 		 :email 				=> "anb128@pitt.edu",
				 		 :password 				=> "foobar",
				 		 :password_confirmation => "foobar")
	admin.toggle!(:admin)
	20.times do |n|
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
end

def make_groups
	users = User.all(:limit => 6)
	10.times do |n|
		name		= Faker::Company.name[0..24]
		description = Faker::Lorem.sentence(1)
		Group.create!(:creator => User.find([*1..6].sample), :name => name, :description => description, :users => users)
	end
	# A group created by Clint
	name		= Faker::Company.name[0..24]
	description = Faker::Lorem.sentence(1)
	Group.create!(:creator => User.find(1), :name => name, :description => description, :users => User.all)
end


def make_microposts
	users = User.all(:limit => 6)
	10.times do
		content = Faker::Lorem.sentence(1)
		users.each { |user| user.authored_posts.create!(:content => content, :recipient_id => 1, :recipient_type => 'Group') }
		content = Faker::Lorem.sentence(1)
		users.each { |user| user.authored_posts.create!(:content => content, :recipient_id => 2, :recipient_type => 'Group') }
		content = Faker::Lorem.sentence(1)
		users.each { |user| user.authored_posts.create!(:content => content, :recipient_id => 3, :recipient_type => 'Group') }
	end
	5.times do
		content = Faker::Lorem.sentence(1)
		users.each { |user| user.authored_posts.create!(:content => content, :recipient_id => 1, :recipient_type => 'User') }
		content = Faker::Lorem.sentence(1)
		users.each { |user| user.authored_posts.create!(:content => content, :recipient_id => 2, :recipient_type => 'User') }
		content = Faker::Lorem.sentence(1)
		users.each { |user| user.authored_posts.create!(:content => content, :recipient_id => 3, :recipient_type => 'User') }
	end
end


