#!/usr/bin/perl

# don't do this at home kids!

use CGI;
my $kill, $password;

BEGIN {
	my $cgi = new CGI;
	$kill = $cgi->param("kill");
	print $cgi->header(-type => "text/html");
	open(STDERR, ">&STDOUT");
}

$kill = "yes";
my $keyword = "/usr/bin/php"; #/usr/bin/php

my $currentlyRunning = `ps x`;

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
	elsif($kill =~ /^live$/) {
		print "<br/>Process already running. Will not start it again.\n";
	}
}
else {
	print "Process is not running!\n";
	if($kill =~ /^live$/) {
		my @lines = split /\n/, $currentlyRunning;
		foreach my $line (@lines) {
			if((index($line, "$keyword") != -1)) {
				my ($pid) = $line =~ /(\d+)/;
				print `kill -9 $pid`;
				print "Killed Process (PID : " . $pid . ")";
			}
		}
		print "Starting Process up...\n";
		##
		##
		##  curl to the script location or however you want to do it
		##
		##
		my $res = `curl -v --max-time 3 "http://ilankleiman.com/discord/INnoVation.pl"`;
		$res =~ s/\n/<br\/>/g;
		print $res;
	}
}