#!/usr/bin/perl

package MessageRequest;

use ApiKeys;

use JSON;
use Try::Tiny;
use Exporter;

our @ISA = qw(Exporter);

#can be
our @EXPORT_OK = qw(MakeDiscordGet MakeDiscordPostJson);
#default
our @EXPORT = qw(MakeDiscordGet MakeDiscordPostJson);

sub MakeDiscordGet {
	my @parms = @_;
	#parms[0] = endpoint /users/\@me
	#parms[1] = 
	#parms[2] = return decoded json, 0=no, 1=yes
	my $userAgent = "DiscordBot (http://ilankleiman.com, 4.0.0)";
	my $contentType = "Content-Type: application/x-www-form-urlencoded";
	my $authorizeCode = "Authorization: Bot $API_DISCORD";
	my $baseURL = "https://discordapp.com/api";
	my $response = `curl -s --max-time 5 -A "$userAgent" -H "$contentType" -H "$authorizeCode" "${baseURL}@{parms[0]}" -L`;
	try {
		$response = decode_json($response) if (@parms[2] =~ /^1$/)
	}
	catch {
		$response = "";
	};
	return $response;
}

sub MakeDiscordPostJson {
	my @parms = @_;
	#parms[0] = endpoint /users/\@me
	#parms[1] = json to post
	#parms[2] = return decoded json, 0=no, 1=yes
	#parms[3] = post type, -X POST/PUT/DELETE/etc...
	my $getType;
	if ( (@parms[3] =~ /^()$/) || (!defined(@parms[3])) ) {
		$getType = "POST";
	}
	else {
		$getType = @parms[3];
	}
	my $userAgent = "DiscordBot (http://ilankleiman.com, 4.0.0)";
	my $contentType = "Content-Type: application/json";
	my $authorizeCode = "Authorization: Bot $API_DISCORD";
	my $baseURL = "https://discordapp.com/api";
	my $response = `curl -s --max-time 5 -X $getType -d '@parms[1]' -A "$userAgent" -H "$contentType" -H "$authorizeCode" "${baseURL}@{parms[0]}" -L`;
	try {
		$response = decode_json($response) if (@parms[2] =~ /^(1)$/)
	}
	catch {
		$response = "";
	};
	return $response;
}

1;