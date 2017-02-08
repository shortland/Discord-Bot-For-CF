#!/usr/bin/perl

use JSON;
use File::Slurp;
use CGI;

our $cookie = "__cfduid=abc";
our $authorization = "abc";
our $superProperties = "abc";

BEGIN {
	$cgi = new CGI;
	print $cgi->header(-type => "image");
	open(STDERR, ">&STDOUT");
}

sub PostMessage {
	my @parms = @_;
	# [0] = message
	# [1] = channel
	if(!defined @parms[0] || !defined @parms[1]) {
		return "No message defined";
	}
	else {
		my $postMessage = `curl -s -A "Discord/59 CFNetwork/808.2.16 Darwin/16.3.0" -H "Content-Type: application/json" -H "Cookie: $cookie" -H "Authorization: $authorization" -H "x-super-properties: $superProperties" -X POST -d '{"content":"@parms[0]","nonce":"278276808804139008","tts":false}' "https://discordapp.com/api/v6/channels/@parms[1]/messages"`;
		return $postMessage;
	}
}

sub ReadChannel {
	my @parms = @_;
	our $processed = read_file("discord.txt");
	our @readMessages = split /\n/, $processed;
	# [0] = channel
	# [1] = enable recursion
	if(defined @parms[0]) {

		my $getMessage = `curl -s -A "Discord/59 CFNetwork/808.2.16 Darwin/16.3.0" -H "Content-Type: application/json" -H "Cookie: $cookie" -H "Authorization: $authorization" -H "x-super-properties: $superProperties" "https://discordapp.com/api/v6/channels/@parms[0]/messages?limit=6"`;
		my $decodedMessage = decode_json($getMessage);

		for(my $i = 0; $i < scalar(@{$decodedMessage}); $i++) {
			#print "Looping through them all " . $i . "\n";
			my $user = $decodedMessage->[$i]{'author'}{'username'};
			if($user =~ /^innovation$/i) {
				#print "Oh i see me, lets skip this one.\n";
				next;
			}
			else {
				my $messageID = $decodedMessage->[$i]{'id'};
				my $messageContent = $decodedMessage->[$i]{'content'};
				#print $messageID;
				$found = "false";
				#print scalar @readMessages;
				for(my $j = 0; $j < scalar @readMessages; $j++) {
					if(@readMessages[$j] =~ /^($messageID)$/) {
						$found = "true";
						last;
					}
				}
				#print $found."\n";
				if($found =~ /^false$/) {
					print "FILTER: " . $messageContent . "\n";
					append_file("discord.txt", $messageID."\n");
					ParseMessage(lc($messageContent), $user, @parms[0]);
				}
				else {
					#print "It's been found before. Don't do anything\n";
				}
			}
		}

		sleep(3);
		ReadChannel(@parms[0]);
		exit;
	}
}

sub ParseMessage {
	my @parms = @_;
	my $myRes;

	if(@parms[0] =~ /^(~help)$/i) {
		$myRes = "Here is a list of commands:";
	}

	PostMessage($myRes, @parms[2]);
}

ReadChannel("215286602883137536");