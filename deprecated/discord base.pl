#!/usr/bin/perl

use JSON;
#use Net::Async::WebSocket::Client;
#use Protocol::WebSocket::URL;
# add bot to server
# go to this link!
# https://discordapp.com/oauth2/authorize?client_id=279345407413321728&scope=bot
# sagan is now in that server
# list what servers i'm in and list their channels, run off those




#my $res = `curl -v -A "DiscordBot (ilankleiman.com, 4.0.0)" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bot " "https://discordapp.com/api/gateway/bot" -L`;

#my $res = `curl -v -A "DiscordBot (http://ilankleiman.com, 4.0.0)" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bot " "https://discordapp.com/api/guilds/279312312093900800/channels" -L`;
#/users/@me/guilds

our $sleptTime = 0;
our $DISCORDAPI = "";
our $DAVID = "base 64 jpeg 128px x 128px data";

our $serverList = `curl -s -A "DiscordBot (http://ilankleiman.com, 4.0.0)" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bot $DISCORDAPI" "https://discordapp.com/api/users/\@me/guilds" -L`;
$serverList = decode_json($serverList);

my @webhooks;
for(my $i = 0; $i < scalar(@{$serverList}); $i++) {
	my $webhookList = `curl -s -A "DiscordBot (http://ilankleiman.com, 4.0.0)" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bot $DISCORDAPI" "https://discordapp.com/api/guilds/$serverList->[$i]{'id'}/webhooks" -L`;
	$webhookList = decode_json($webhookList);
	@webhooks = ();
	for(my $j = 0; $j < scalar(@{$webhookList}); $j++) {
		if($webhookList->[$j]{'name'} =~ /^DavidKimWH$/) {
			@webhooks[$j] = $webhookList->[$j]{'channel_id'};
		}
		else {
			print "not " . $webhookList->[$j]{'name'} . " end not\n";
		}
	}
	if($webhookList->[0]{'channel_id'} =~ /^()$/) {
		print "Looks like there are no webhooks, creating one for each channel...";
	}

	my $channelList = `curl -s -A "DiscordBot (http://ilankleiman.com, 4.0.0)" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bot $DISCORDAPI" "https://discordapp.com/api/guilds/$serverList->[$i]{'id'}/channels" -L`;
	my $channelList = decode_json($channelList);
	for(my $j = 0; $j < scalar(@{$channelList}); $j++) {
		if(($channelList->[$j]{'type'} ~~ "text")) {
			my $channelID = $channelList->[$j]{'id'};
			if($channelID ~~ @webhooks) { }
			else {
				print "Making WebHook for channel " . $channelID . " \n";
				`curl -s -H "Content-Type: application/json" -X POST -d '{"name":"DavidKimWH", "avatar" : "$DAVID"}' -A "DiscordBot (ilankleiman.com, 4.0.0)" -H "Authorization: Bot $DISCORDAPI" "https://discordapp.com/api/channels/$channelID/webhooks" -L`;
			}
		}
	}
	$webhookList = `curl -s -A "DiscordBot (http://ilankleiman.com, 4.0.0)" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bot $DISCORDAPI" "https://discordapp.com/api/guilds/$serverList->[$i]{'id'}/webhooks" -L`;
	$webhookList = decode_json($webhookList);
	@webhooks = ();
	for(my $j = 0; $j < scalar(@{$webhookList}); $j++) {
		if($webhookList->[$j]{'name'} =~ /^DavidKimWH$/) {
			@webhooks[$j] = $webhookList->[$j]{'channel_id'} . " " . $webhookList->[$j]{'id'} . " " . $webhookList->[$j]{'token'};
		}
	}
}
$sleptTime += 3;
#sleep(3);


for(my $j = 0; $j < scalar(@webhooks); $j++) {
	my @words = split / /, @webhooks[$j];
	if (@words[0] =~ /^CHANNEL$/) {
		my $postMessage = `curl -s -A "DiscordBot (http://ilankleiman.com, 4.0.0)" -H "Content-Type: application/json" -X POST -d '{"content" : "test"}' -H "Authorization: Bot $DISCORDAPI" "https://discordapp.com/api/webhooks/@words[1]/@words[2]" -L`;
	}
}
