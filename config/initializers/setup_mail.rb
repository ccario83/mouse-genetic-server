# Uses a gmail accound setup for berndtlab.pitt.edu to send contact/comment forms to the web admin
ActionMailer::Base.smtp_settings = {
	:address              => "smtp.gmail.com",
	:port                 => 587,
	:domain               => "berndtlab.pitt.edu",
	:user_name            => "contactberndtlab",
	:password             => 'xD1METDmClybm9UwGzthCDQontRWJDCOH3YMGNznisbD1eKrXEaxCJTJBq1wjDI',
	:authentication       => "plain",
	:enable_starttls_auto => true
}
