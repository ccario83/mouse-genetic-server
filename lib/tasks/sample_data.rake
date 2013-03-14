namespace :db do 
	desc "Fill database with sample data"
	task :populate => :environment do
		make_users
		make_groups
		make_microposts
		make_tasks
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
	# A group created by Clint, Annerose and person 3 are members, tasks will appear here
	group = Group.create!(:creator => User.find(1), :name => 'Clint owned group 1', :description => 'To make sure that owned group functions work')
	group.users << User.all(:limit => 5)
	group.save
	# Confirm Clint's membership for this group
	User.find(1).confirm_membership(group)
	
	
	# Another group created by Clint
	group = Group.create!(:creator => User.find(1), :name => 'Clint owned group 2', :description => 'Another owned group with no tasks')
	group.users << User.all(:limit => 5)
	group.save
	# Confirm Clint's membership for this group
	User.find(1).confirm_membership(group)
	
	# 15 more groups with random creators and members
	15.times do |n|
		name		= Faker::Company.name[0..24]
		description = Faker::Lorem.sentence(1)
		creator = User.all.sample(1)[0]
		group = Group.create!(:creator => creator, :name => name, :description => description)
		group.users << User.all.sample(6)
		group.save
		creator.confirm_membership(group)
	end
end


def make_microposts
	users = User.all(:limit => 6)
	10.times do
		users.each { |user| user.authored_posts.create!(:content => Faker::Lorem.sentence(1), :recipient_id => 1, :recipient_type => 'Group') }
		users.each { |user| user.authored_posts.create!(:content => Faker::Lorem.sentence(1), :recipient_id => 2, :recipient_type => 'Group') }
		users.each { |user| user.authored_posts.create!(:content => Faker::Lorem.sentence(1), :recipient_id => 3, :recipient_type => 'Group') }
	end
	5.times do
		users.each { |user| user.authored_posts.create!(:content => Faker::Lorem.sentence(1), :recipient_id => 1, :recipient_type => 'User') }
		users.each { |user| user.authored_posts.create!(:content => Faker::Lorem.sentence(1), :recipient_id => 2, :recipient_type => 'User') }
		users.each { |user| user.authored_posts.create!(:content => Faker::Lorem.sentence(1), :recipient_id => 3, :recipient_type => 'User') }
	end
end


def make_tasks
	Task.create!(:creator_id => 1, :description => 'Please send me the latest micropost page specs', :group_id => 1, :assignee_id => 2, :due_date => Time.now+rand(10000000)
)
	Task.create!(:creator_id => 1, :description => 'Please compute the latest data', :group_id => 1, :assignee_id => 3, :due_date => Time.now+rand(10000000)
)
	Task.create!(:creator_id => 2, :description => 'Finish micropost pages', :group_id => 1, :assignee_id => 1, :due_date => Time.now+rand(10000000)
)
	Task.create!(:creator_id => 3, :description => 'Can I have the latest data', :group_id => 1, :assignee_id => 2, :due_date => Time.now+rand(10000000)
)
end


