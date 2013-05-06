namespace :db do 
	desc "Fill database with sample data"
	task :populate => :environment do
		make_users
		make_groups
		make_microposts
		make_tasks
		make_datafiles
		make_jobs
	end
end

def make_users
	admin = User.create(:first_name 			=> "Clint",
						:last_name				=> "Cario",
						:institution			=> "University of Pittsburgh",
						:email 					=> "clint.cario@gmail.com",
						:password 				=> "foobar",
						:password_confirmation	=> "foobar")
	admin.save!
	admin.toggle!(:admin)
	admin = User.create(:first_name 			=> "Annerose",
						:last_name				=> "Berndt",
						:institution			=> "University of Pittsburgh",
						:email 					=> "anb128@pitt.edu",
						:password 				=> "foobar",
						:password_confirmation	=> "foobar")
	admin.save!
	admin.toggle!(:admin)
	20.times do |n|
		first_name	= Faker::Name.name.split()[0]
		last_name 	= Faker::Name.name.split()[1]
		institution = "Some Other Place"
		email		= "example-#{n+1}@otherplace.org"
		password	= "password"
		user = User.create( :first_name 			=> first_name,
							:last_name 				=> last_name,
							:email 					=> email,
							:institution			=> institution,
							:password 				=> password,
							:password_confirmation 	=> password)
		user.save!
	end
end

def make_groups
	# A group created by Clint, Annerose and person 3 are members, tasks will appear here
	group = Group.create(:creator => User.find(1), :name => 'Clint owned group 1', :description => 'To make sure that owned group functions work')
	group.users << User.all(:limit => 5)
	group.save!
	# Confirm Clint's membership for this group
	User.find(1).confirm_membership(group)
	
	
	# Another group created by Clint
	group = Group.create(:creator => User.find(1), :name => 'Clint owned group 2', :description => 'Another owned group with no tasks')
	group.users << User.all(:limit => 5)
	group.save!
	# Confirm Clint's membership for this group
	User.find(1).confirm_membership(group)
	
	# 15 more groups with random creators and members
	15.times do |n|
		name		= Faker::Company.name[0..24]
		description = Faker::Lorem.sentence(1)
		creator = User.all.sample(1)[0]
		group = Group.create(:creator => creator, :name => name, :description => description)
		group.users << User.all.sample(6)
		group.save!
		creator.confirm_membership(group)
	end
end


def make_microposts
	users = User.all.sample(5)
	users << User.first
	# single group
	users.each do |user| 
		group = user.groups.sample(1)[0]
		user.confirm_membership(group)
		user.post_message_to_group(group, 'Test: ' + user.name + ' posting to single group ' + group.name )
	end
	# multiple groups
	users.each do |user| 
		groups = user.groups.sample(3)
		groups.each { |group| user.confirm_membership(group) }
		user.post_message_to_groups(groups, 'Test: ' + user.name + ' posting to 3 groups at once')
	end
	
	# single user
	users.each do |poster| 
		user = User.all.sample(1)[0]
		poster.post_message_to_user(user, 'Test: ' + poster.name + ' posting to single user ' + user.name )
	end
	# multiple users
	users.each { |poster| poster.post_message_to_users(User.all.sample(3), 'Test: ' + poster.name + ' posting to 3 users at once') }
		
	user = User.all.sample(1)[0]
	group = user.groups.sample(1)[0]
	user.confirm_membership(group)
	user.post_message_to_group(group, 'Test: ' + user.name + ' posting to first group' )
	user.post_message_to_user(User.first, 'Test: ' + user.name + ' posting to Clint directly' )
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
	10.times do |n|
		description = Faker::Lorem.sentence(1)
		Task.create!(:creator_id => 1, :description => description, :group_id => 1, :assignee_id => 2, :due_date => Time.now+rand(10000000)
)
	end
end

def make_datafiles
	user = User.first
	isgood = user.datafiles.new()
	isgood.process_local_file(File.join(Rails.root, 'lib/tasks/GOOD.txt'))
	isgood.description = 'Runnable with UWF'
	isgood.save!
	
	nogood = user.datafiles.new()
	nogood.process_local_file(File.join(Rails.root, 'lib/tasks/NoGOOD.txt'))
	nogood.description = 'Not runnable with UWF'
	nogood.save!
end

def make_jobs
	user = User.first
	
	isgood = Datafile.first
	nogood = Datafile.find(2)

	user.jobs.create!(:name => 'Starting', :description => 'A test UWF that is still starting', :runner => 'UWF', :state => 'Starting', :datafile => isgood)
	user.jobs.create!(:name => 'Progressing', :description => 'A test UWF job in progress', :runner => 'UWF', :state => 'Progressing', :datafile => isgood)
	user.jobs.create!(:name => 'Failed', :description => 'A test UWF job that failed', :runner => 'UWF', :state => 'Failed', :datafile => nogood)
	user.jobs.create!(:name => 'Completed', :description => 'A test UWF job that completed', :runner => 'UWF', :state => 'Completed', :datafile => isgood)
end

