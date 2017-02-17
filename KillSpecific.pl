#!/usr/bin/perl

# don't do this at home kids!

use CGI;
# will kill running processes that match this keyword
my $keyword = "Running.pl"; #/usr/bin/php
my $kill, $password;

BEGIN {
	my $cgi = new CGI;
	$kill = $cgi->param("kill");
	$password = $cgi->param("password");
	print $cgi->header(-type => "text/html");
	open(STDERR, ">&STDOUT");
}

# prevent accidental webpage load
if(!defined $password) {
	print "<form action='' method='post'>password: <input type='text' name='password'><br/><input type='hidden' name='kill' value='$kill'><input type='submit' value='do it billy!'>";
	exit;
}
elsif($password !~ /^password$/) {
	print "<h3 style='color:red;'>WRONG PASSWORD</h3>";
	print "<form action='' method='post'>password: <input type='text' name='password'><br/><input type='hidden' name='kill' value='$kill'><input type='submit' value='do it billy!'>";
	exit;
}

if($kill =~ /^restart$/) {
	system('curl -s "http://138.197.50.244/DISCORD/Running.pl?password=password&kill=yes"');
	system('nohup curl -s "http://138.197.50.244/DISCORD/Running.pl?password=password&kill=live"');
}

my $currentlyRunning = `ps aux`;
if((index($currentlyRunning, "$keyword") != -1)) {
	print "Process is currently running!\n";
	if($kill =~ /^yes$/) {
		my @lines = split /\n/, $currentlyRunning;
		foreach my $line (@lines) {
			if((index($line, "$keyword") != -1)) {
				my ($pid) = $line =~ /(\d+)/;
				print `kill -9 $pid`;
				print "Killed Process (PID : " . $pid . ")";
			}
		}
	}
}