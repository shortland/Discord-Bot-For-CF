#!/usr/bin/perl

use File::Slurp;
use AnyEvent::WebSocket::Client;
use CGI;

BEGIN {
	$cgi = new CGI;
	$version = $cgi->param("version");
	print $cgi->header(-type => "text");
	open(STDERR, ">&STDOUT");
}
append_file("output/lives.txt", "1\n");
ShowOnline();
sub ShowOnline {
	print "executing online";
	my $client = AnyEvent::WebSocket::Client->new(
	  http_headers => [
		'connection' => 'keep-alive, Upgrade', 
		'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.12; rv:47.0) Gecko/20100101 Firefox/47.0', 
		'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8', 
		'Sec-WebSocket-Version' => '13', 
		'origin' => 'https://discordapp.com', 
		'Sec-WebSocket-Extensions' => 'permessage-deflate', 
		'Sec-WebSocket-Key' => 'NLt08EpBPfoQAZI0gcxZJw==', 
		'Cookie' => '__cfduid=dec5cf93627559c6c3d198a734dd3e28a1486993532', 
		'Pragma' => 'no-cache', 
		'Upgrade' => 'websocket',
	  ],
	);

	my $popo = $client->connect("wss://gateway.discord.gg/?encoding=json&v=6")->cb(sub {
		our $connection = eval { shift->recv };
		if($@) {
			warn $@;
			return;
		}

		$connection->send('{"op":2,"d":{"token":"Mjc5NDM0NzkyNTkwNjM5MTA0.C4OkaQ.ydecF7SZrNBxYqc44OnK0UWOqUs","properties":{"os":"Mac OS X","browser":"Firefox","device":"","referrer":"","referring_domain":""},"large_threshold":100,"synced_guilds":[],"presence":{"status":"online","since":0,"afk":false,"game":{"name" :"SCII Balance Designer '.$version.'"}},"compress":true}}');
		$connection->on(each_message => sub {
			my($connection, $message) = @_;
			# print "yolo:".$connection."<<";
			# print $message;
		});

		$connection->on(finish => sub {
			my($connection) = @_;
			...
		});
		$connection->close;
	});
	AnyEvent->condvar->recv;
}