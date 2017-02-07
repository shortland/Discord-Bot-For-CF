#!/usr/bin/perl

use JSON;
use File::Slurp;
use threads;
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
		#print "I'm supposed to get recent messages\n";

		my $getMessage = `curl -s -A "Discord/59 CFNetwork/808.2.16 Darwin/16.3.0" -H "Content-Type: application/json" -H "Cookie: $cookie" -H "Authorization: $authorization" -H "x-super-properties: $superProperties" "https://discordapp.com/api/v6/channels/@parms[0]/messages?limit=6"`;
		my $decodedMessage = decode_json($getMessage);

		#print "I got last 6 messages\n";
		#print "There are " . scalar(@{$decodedMessage})."\n";
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

		# show typing on discord servers
		`curl -s -H "Content-Length: 0" --referer "https://discordapp.com/channels/199730784393756672/215286602883137536" -H "Accept-Encoding: gzip, deflate" -A "Discord/59 CFNetwork/808.2.16 Darwin/16.3.0" -H "Content-Type: text/html; charset=utf-8" -H "Cookie: $cookie" -H "Authorization: $authorization" -H "X-Super-Properties: $superProperties" "https://discordapp.com/api/v6/channels/@parms[0]/typing" -X POST`;

		sleep(3);
		ReadChannel(@parms[0]);
		exit;
	}
}

sub ParseMessage {
	my @parms = @_;
	my $myRes;
	#$randomelement = $array[rand @array];
	if(@parms[1] =~ /^(ashortland)$/i) {
		print "a god has sponken";
		$myRes = "Hi lord <@!131231443694125056>";
	}
	else {
		# add fancy regex here, reply to certain keywords or commands etc
	}

	PostMessage($myRes, @parms[2]);
}


my $t1 = async{ReadChannel("199730784393756672");};
my $t2 = async{ReadChannel("215286602883137536");};

my $output1 = $t1->join;
my $output2 = $t2->join;

print for $output1, $output2;