#!/usr/bin/env perl

use JSON;
use File::Slurp;
use URI::Encode qw(uri_encode uri_decode);
use Try::Tiny;
use MIME::Base64;
use AnyEvent::WebSocket::Client;
use Math::Round;
use CGI;

# my
use ApiKeys;
use TextEscape;
use PublicArrays;
use MessageRequest;
# #

BEGIN {
	$cgi = new CGI;
	print $cgi->header(-type => "text");
	open(STDERR, ">&STDOUT");
}

our $BALANCEVERSION = "4";
our $runTime = 0;
our $BotNameCall = "";

our @liveStreaming = split("\n", read_file("output/streamers.txt"));



GetAndMakeHooks(MyBotName(), MyServers());

sub MyServers {
	#
	return MakeDiscordGet("/users/\@me/guilds", "", "1");
}

# this is stupid can i do it a different way?
sub MyBotNameCheck {
	if ($BotNameCall =~ /^()$/) {
		print "Have to create new instance of name\n";
		$BotNameCall = MyBotName();
		return $BotNameCall;
	}
	else {
		return $BotNameCall;
	}
}

sub MyBotName {
	return MakeDiscordGet("/users/\@me", "", "1")->{'username'};
}

sub GetAndMakeHooks {
	my @parms = @_;
	# @parms[0] = bot name
	# @parms[1] = array of servers bot is in
	print "Loading webhooks...\n";
	write_file("buffers/channel_buffer.txt", ""); # holds list of channels
	write_file("buffers/webhook_buffer.txt", ""); # holds list of webhooks created
	for(my $i = 0; $i < scalar(@{$parms[1]}); $i++) {

		## delete any pre-existing david kim webhooks,... just cause easier/quicker than having to check if exists for x channel then remake
		my $webhookList = MakeDiscordGet("/guilds/@parms[1]->[$i]{'id'}/webhooks", "", "1");
		for(my $j = 0; $j < scalar(@{$webhookList}); $j++) {
			if($webhookList->[$j]{'name'} =~ /^(@parms[0])$/) {
				MakeDiscordPostJson("/webhooks/".$webhookList->[$j]{'id'}, "", "1", "DELETE");
			}
		}
		# @webhooks contains channel ids of channels which have correct webhooks already
		my $channelList = MakeDiscordGet("/guilds/@parms[1]->[$i]{'id'}/channels", "", "1");
		my $picture = read_file("static/picture");
		for(my $j = 0; $j < scalar(@{$channelList}); $j++) {
			if(($channelList->[$j]{'type'} =~ /^text$/)) {
				append_file("buffers/channel_buffer.txt", $channelList->[$j]{'id'}."|");
				MakeDiscordPostJson("/channels/".$channelList->[$j]{'id'}."/webhooks", '{"name":"'.@parms[0].'", "avatar" : "'.$picture.'"}', "1");
			}
		}
		$webhookList = MakeDiscordGet("/guilds/@parms[1]->[$i]{'id'}/webhooks", "", "1");
		for(my $j = 0; $j < scalar(@{$webhookList}); $j++) {
			if($webhookList->[$j]{'name'} =~ /^(@parms[0])$/) {
				append_file("buffers/webhook_buffer.txt", ($webhookList->[$j]{'channel_id'} . "|" . $webhookList->[$j]{'id'} . "|" . $webhookList->[$j]{'token'}."\n"));
			}
		}
	}
	print "done.\n";
	GetChannels();
}

sub GetChannels {
	my @channels = split(/\|/, read_file("buffers/channel_buffer.txt"));
	print time."\n";
	for(my $j = 0; $j < scalar(@channels); $j++) {
		ReadChannel(@channels[$j]);
		sleep(0.2);
	}

	$runTime += 2;
	if($runTime > 120) {
		print "reseting runtime ";
		for(my $j = 0; $j < scalar(@channels); $j++) {
			my $decodedChannel = MakeDiscordGet("/channels/@channels[$j]", "", "1");
			if(lc($decodedChannel->{'name'}) =~ /^(streams|streaming)$/) {
				StreamTesting(@channels[$j]);
				print "LOOKING STREAMS\n";
			}
		}
		`curl -s --max-time 5 'http://138.197.50.244/DISCORD/ShowOnline.pl?version=$BALANCEVERSION'`;
		$runTime = 0;
	}

	print "finished instance run at: ";
	return GetChannels();
}

sub ReadChannel {
	my @parms = @_;
	#print "reading channel @parms[0]\n";
	my @readMessages = split(/\|/, read_file("buffers/message_buffer.txt"));
	my $decodedMessage = MakeDiscordGet("/channels/@parms[0]/messages?limit=6", "", "1");
	
	try {
		if(scalar(@{$decodedMessage}) >= 0) {
			# safe
		}
		else {
			print "not safe, quit read\n";
			return;
		}
	}
	catch {
		print "really unsafe, quitting read\n";
		return;
	};


	for(my $i = 0; $i < scalar(@{$decodedMessage}); $i++) {
		my $user = uri_encode($decodedMessage->[$i]{'author'}{'username'});
		my $attachments = $decodedMessage->[$i]{'attachments'}[0]{'url'};
		my $myName = MyBotNameCheck();
		$myName =~ s/ /\%20/g;
		if($user =~ /^($myName)$/i) {
			next;
		}
		else {
			my $messageID = $decodedMessage->[$i]{'id'};
			my $messageContent = $decodedMessage->[$i]{'content'};

			$found = "false";
			for(my $j = 0; $j < scalar @readMessages; $j++) {
				if(@readMessages[$j] =~ /^($messageID)$/) {
					$found = "true";
					last;
				}
			}

			if($found =~ /^false$/) {
				print "FILTER: " . $messageContent . "\n";
				append_file("buffers/message_buffer.txt", $messageID."|");

				####### Need to make work on server
				# if ($attachments =~ /SC2Replay/) {
				# 	print "is attachment type replay\n";
				# 	`curl -s "$attachments" >output/testing.SC2Replay`;
				# 	`./parse.pl`;
				# 	$balance = read_file("output/balance.txt");
				# 	$balance =~ s/\n/\\\\n/g;
				# 	WriteWebHook("`".$balance."\\nMUCH BALANCE!!!`", @parms[0]);
				# }

				ParseMessage(lc($messageContent), $user, @parms[0]);
			}
		}
	}
}

sub WriteWebHook {
	my @parms = @_;
	my @webhooks = split(/\n/, read_file("buffers/webhook_buffer.txt"));
	for(my $j = 0; $j < scalar(@webhooks); $j++) {
		if(!defined @parms[0] || !defined @parms[1] || @parms[0] =~ /^nil$/) {
			last; # print "No message defined";
		}
		elsif (length(@parms[0]) >= 2000) {
			WriteWebHook("Message limit is not allowed to exceed 2000 characters", @parms[1]);
			last;
		}
		else {
			my @words = split(/\|/, @webhooks[$j]);
			if (@words[0] =~ /^@parms[1]$/) {
				if(@parms[2] =~ /^base64$/) {
					@parms[0] = decode_base64(@parms[0]);
					#@parms[0] = uri_encode(@parms[0]);
					@parms[0] = cURLEscape(@parms[0]);
					@parms[0] = "`".@parms[0] . "`";
					print @parms[0];
				}
				print MakeDiscordPostJson("/webhooks/@words[1]/@words[2]", '{"content" : "'.@parms[0].'"}', "1", "");
			}
		}
	}
}

sub GetLeagueNumber {
	my @parms = @_;
	for(my $i = 0; $i < 7; $i++) {
		if(@parms[0] =~ /^@PUBLIC_league[$i]$/) {
			$leagueNum = $i;
			last;
		}
	}
	return @PUBLIC_emojies[$leagueNum];
}

sub GetRaceNumber {
	my @parms = @_;
	for(my $i = 0; $i < 4; $i++) {
		if(@parms[0] =~ /^@PUBLIC_race[$i]$/) {
			$racenum = $i;
			last;
		}
	}
	return @PUBLIC_raceEmojies[$racenum];
}

sub ParseMessage {
	my @parms = @_;

	if (substr(@parms[0], 0, 1) !~ /^(~)$/) {
		return;
	}

	if (length(@parms[0]) <= 1) {
		return;
	}
	elsif (@parms[0] =~ /^(~ping)$/i) {
		WriteWebHook("pong", @parms[2]);
	}
	elsif (@parms[0] =~ /^(~help)$/i) {
		my $help = read_file("static/help.txt");
		$help =~ s/\n/\\n/g;
		WriteWebHook($help, @parms[2]);
	}
	elsif ((index(@parms[0], "~roster") != -1) && (substr(@parms[0], 0, 1) =~ /^(~)$/) ){
		#print "im doing parse";
		my $data = `curl -s "http://ilankleiman.com/JoinMembers.php"`;
		if($data =~ /^(\[\])$/) {
			WriteWebHook("League data request failed", @parms[2]);
			return;
		}
		else {
			$data = decode_json($data);
		}

		my @searchParms = split(" ", @parms[0]);
		my @people = ();

		if(defined(@searchParms[1])) {
			if(@searchParms[1] =~ /^count$/) {
				if (lc(@searchParms[2]) =~ /^league$/) {
					my $bronze = 0, $silver = 0, $gold = 0, $platinum = 0, $diamond = 0, $master = 0, $grandmaster = 0;
					for(my $i = 0; $i < scalar(@{$data}); $i++) {						
						#actual league "DIAMOND"
						my $realL = uc($data->[$i]{'league'});

						$bronze++ if($realL =~ /^BRONZE$/);
						$silver++ if($realL =~ /^SILVER$/);
						$gold++ if($realL =~ /^GOLD$/);
						$platinum++ if($realL =~ /^PLATINUM$/);
						$diamond++ if($realL =~ /^DIAMOND$/);
						$master++ if($realL =~ /^MASTER$/);
						$grandmaster++ if($realL =~ /^GRANDMASTER$/);
					}
					push(@people, "Here are some league stats for the clan:\\n");
					my $totalRanked = ($bronze+$silver+$gold+$platinum+$diamond+$master+$grandmaster);
					push(@people, GetLeagueNumber("GRANDMASTER") . " x " . $grandmaster . "  (" . nearest(.01, (($grandmaster/$totalRanked)*100)) . "\%)\\n");
					push(@people, GetLeagueNumber("MASTER") . " x " . $master . "  (" . nearest(.01, (($master/$totalRanked)*100)) . "\%)\\n");
					push(@people, GetLeagueNumber("DIAMOND") . " x " . $diamond . "  (" . nearest(.01, (($diamond/$totalRanked)*100)) . "\%)\\n");
					push(@people, GetLeagueNumber("PLATINUM") . " x " . $platinum . "  (" . nearest(.01, (($platinum/$totalRanked)*100)) . "\%)\\n");
					push(@people, GetLeagueNumber("GOLD") . " x " . $gold . "  (" . nearest(.01, (($gold/$totalRanked)*100)) . "\%)\\n");
					push(@people, GetLeagueNumber("SILVER") . " x " . $silver . "  (" . nearest(.01, (($silver/$totalRanked)*100)) . "\%)\\n");
					push(@people, GetLeagueNumber("BRONZE") . " x " . $bronze . "  (" . nearest(.01, (($bronze/$totalRanked)*100)) ."\%)\\n");
					push(@people, "Total Ranked: " . $totalRanked . "\\n");
					push(@people, "\\n");
				}
				elsif(lc(@searchParms[2]) =~ /^race$/) {
					my $terran = 0, $zerg = 0, $protoss = 0, $random = 0;
					for(my $i = 0; $i < scalar(@{$data}); $i++) {						
						#actual league "DIAMOND"
						my $realL = uc($data->[$i]{'race'});

						$terran++ if($realL =~ /^TERRAN$/);
						$zerg++ if($realL =~ /^ZERG$/);
						$protoss++ if($realL =~ /^PROTOSS$/);
						$random++ if($realL =~ /^RANDOM$/);						
					}

					push(@people, "Here are some race stats for the clan:\\n");
					my $totalRanked = ($terran+$zerg+$protoss+$random);
					push(@people, GetRaceNumber("TERRAN") . " x " . $terran . "  (" . nearest(.01, (($terran/$totalRanked)*100)) . "\%)\\n");
					push(@people, GetRaceNumber("ZERG") . " x " . $zerg . "  (" . nearest(.01, (($zerg/$totalRanked)*100)) . "\%)\\n");
					push(@people, GetRaceNumber("PROTOSS") . " x " . $protoss . "  (" . nearest(.01, (($protoss/$totalRanked)*100)) . "\%)\\n");
					push(@people, GetRaceNumber("RANDOM") . " x " . $random . "  (" . nearest(.01, (($random/$totalRanked)*100)) . "\%)\\n");
					push(@people, "Total Ranked: " . $totalRanked . "\\n");
					push(@people, "\\n");
				}
				else {
					WriteWebHook("I couldnt find that filter, try: \\n~roster count league \\n or \\n~roster count race", @parms[2]);
					return;
				}
			}
			else {
				for(my $i = 0; $i < scalar(@{$data}); $i++) {
					my $league = GetLeagueNumber(uc($data->[$i]{'league'}));
					my $realL;

					#reformat serachParms for lazy people like myself
					@searchParms[1] = "GRANDMASTER" if (@searchParms[1] =~ /^(gm|grandmasters)$/i);
					@searchParms[1] = "PLATINUM" if (@searchParms[1] =~ /^(plat|platinums)$/i);
					@searchParms[1] = "MASTER" if (@searchParms[1] =~ /^(masters)$/i);

					if (uc(@searchParms[1]) ~~ @PUBLIC_league) {
						$realL = uc($data->[$i]{'league'});
					}
					elsif (uc(@searchParms[1]) ~~ @PUBLIC_race) {
						$realL = uc($data->[$i]{'race'});
					}
					elsif (uc(@searchParms[1]) ~~ @PUBLIC_clanTags) {
						$realL = uc($data->[$i]{'clan_tag'});
					}
					else {
						WriteWebHook("I couldnt find that filter", @parms[2]);
						last;
					}

					if (uc(@searchParms[1]) =~ /^($realL)$/i) {
						push(@people, "" . $league . " [" . $data->[$i]{'clan_tag'} . "] ". $data->[$i]{'name'}." (mmr: " . $data->[$i]{'mmr'} . ")\\n");
					}
				}
			}
		}
		else {
			for(my $i = 0; $i < scalar(@{$data}); $i++) {
				my $league = GetLeagueNumber(uc($data->[$i]{'league'}));
				push(@people, "" . $league . " [" . $data->[$i]{'clan_tag'} . "] ". $data->[$i]{'name'}." (mmr: " . $data->[$i]{'mmr'} . ")\\n");
			}
		}

		$text = "";
		$j = 0;
		for(my $i = 0; $i < scalar @people; $i++) {
			$text .= @people[$i];
			if(($j > 20) || (($i+1) =~ (scalar @people))) {
				WriteWebHook($text, @parms[2]);
				$text = "";
				$j = 0;
			}
			$j++;
		}
	}
	elsif ((index(@parms[0], "~translate") != -1) && (substr(@parms[0], 0, 1) =~ /^(~)$/) ){
		@parms[0] =~ s/~translate //g;
		my $search = lc(@parms[0]);

		my @searchParms = split(" ", $search);
		my $fromLanguage = @searchParms[0];
		my $toLanguage = @searchParms[1];
		if($toLanguage =~ /^kr$/) {
			$toLanguage = "ko";
		}
		if($fromLanguage =~ /^kr$/) {
			$fromLanguage = "ko";
		}

		my $content = join(' ', @searchParms[2..$#searchParms]);
		$content = uri_encode($content);

		my $response = `curl -s -X POST -H "Content-Type: application/x-www-form-urlencoded" "https://translate.yandex.net/api/v1.5/tr.json/translate?lang=$fromLanguage-$toLanguage&key=$API_YANDEX" -d "text=$content"`;
		my $decodedRes = decode_json($response);

		my $translated = $decodedRes->{'text'}[0];

		if($translated =~ /^$/) {
			$translated = $decodedRes->{'message'};
		}
		my $extra = "\\nTranslation Powered by Yandex.Translate\\n http://translate.yandex.com/";
		WriteWebHook($translated . "\\n" . $extra, @parms[2]);
	}
	elsif ((index(@parms[0], "~islive") != -1) && (substr(@parms[0], 0, 1) =~ /^(~)$/) ){
		@parms[0] =~ s/~islive //g;
		my $search = lc(@parms[0]);

		my $data = `curl -s "http://ilankleiman.com/test.pl?username=$search"`;
		if($data =~ /^Stream offline$/) {
			WriteWebHook($data, @parms[2]);
		}
		elsif($data =~ /^$search playing $/) {
			WriteWebHook("user not found", @parms[2]);
		}
		else {
			print "is live!";
			WriteWebHook("" . $data . " https://twitch.tv/$search", @parms[2]);
		}
	}
	elsif ((index(@parms[0], "~player") != -1) && (substr(@parms[0], 0, 1) =~ /^(~)$/) ){
		my $data = `curl -s "http://ilankleiman.com/JoinMembers.php"`;
		try {
			$data = decode_json($data);
		} 
		catch {
			print "couldnt get JoinMembers.php";
			WriteWebHook("Exceeded max resources on host server", @parms[2]);
			return;
		};
		@parms[0] =~ s/~player //g;
		my $search = lc(@parms[0]);
		if(index($search, "#") != -1) { 
			##
			#print "no error?";
		}
		else {
			WriteWebHook("Please specify their Battle Tag #. ie: ~player Shortland#952", @parms[2]);
			print "sending error";
			return;
		}
		my $text = "";
		my $found = "no";
		for(my $i = 0; $i < scalar(@{$data}); $i++) {
			$r = $data->[$i]{'name'};
			if($search =~ /^($r)$/i) {
				if ($data->[$i]{'race'} =~ /^Protoss$/i) {
					$race = "<:PROTOSS:278762398347689984>";
				}
				elsif ($data->[$i]{'race'} =~ /^Terran$/i) {
					$race = "<:TERRAN:278762425552207883>";
				}
				elsif ($data->[$i]{'race'} =~ /^Zerg$/i) {
					$race = "<:ZERG:278762452265467907>";
				}
				else {
					$race = "<:RANDOM:278762354001444864>";
				}

				$found = "yes";
				my $league = GetLeagueNumber(uc($data->[$i]{'league'}));
				$text .= "" . $league . "(".$data->[$i]{'tier'}.") __**" . $search . "**__ " . $race . "\\n";
				$text .= " __Clan:__ " . $data->[$i]{'clan_tag'} . "\\n";
				$text .= " __MMR:__ " . $data->[$i]{'mmr'} . "\\n\\n";

				$text .= " __Wins:__ " . $data->[$i]{'wins'} . "\\n";
				$text .= " __Losses:__ " . $data->[$i]{'losses'} . "\\n";
				$text .= " __Ties:__ " . $data->[$i]{'ties'} . "\\n";
				$text .= " __Win Rate:__ " . ($data->[$i]{'win_rate'} * 100) . "%\\n\\n";

				$text .= " __Highest Win Streak:__ " . $data->[$i]{'longest_win_streak'} . "\\n";
				$text .= " __Current Win Streak:__ " . $data->[$i]{'current_win_streak'} . "\\n\\n";

				$text .= " __Rank:__ #" . $data->[$i]{'current_rank'} . "\\n";
				$text .= " __Points:__ " . $data->[$i]{'points'} . "\\n";
				$text .= " __Last 1v1:__ " . (scalar localtime $data->[$i]{'last_played_time_stamp'}) . "\\n\\n";
				$text .= " __BattleNet Tag:__ " . $data->[$i]{'battle_tag'} . "\\n";
				$text .= "http://us.battle.net/sc2/en" . $data->[$i]{'path'} . "\/\\n";
				WriteWebHook($text, @parms[2]);
			}
		}
		if($found =~ /^no$/) {
			WriteWebHook("I cannot find that person in any of the confed clans.", @parms[2]);
		}
	}
	elsif ((index(@parms[0], "~streams") != -1) && (substr(@parms[0], 0, 1) =~ /^(~)$/) ){
		@parms[0] =~ s/~streams //g;
		my $type = lc(@parms[0]);
		my $streamers;
		if($type =~ /^all$/) {
			$streamers = read_file("output/streamers.txt");
			$streamers =~ s/\n/\\n/g;
			WriteWebHook("Streams I check:\\n" . $streamers, @parms[2]);
		}
		elsif($type =~ /^live$/) {
			$streamers = read_file("output/currentLive.txt");
			#my @onlineStreams = split("\n", $streamers);
			$streamers =~ s/\n/\\n/g;
			WriteWebHook("Currently online streams:\\n" . $streamers, @parms[2]);
		}
		else {
			WriteWebHook("I cannot find that method, try:\\n~streams all\\n or\\n~streams live", @parms[2]);
		}
	}
	elsif ((index(@parms[0], "~chat") != -1) && (substr(@parms[0], 0, 1) =~ /^(~)$/) ){
		@parms[0] =~ s/~chat //g;
		my $query = lc(@parms[0]);

		$query = uri_encode($query);
		print $query;
		# API.ai API. I like this more
		my $clever = `curl -s -H "Authorization: Bearer $API_AI" "https://api.api.ai/v1/query?v=20150910&query=$query&lang=en&sessionId=1234567890"`;

		my $deClever = decode_json($clever);
		my $cleverRes = $deClever->{'result'}{'fulfillment'}{'speech'};
		my $myRes;
		$myRes = $cleverRes;
		$myRes =~ s/'//g;
		WriteWebHook($myRes, @parms[2]);
	}
	elsif(substr(@parms[0], 0, 1) =~ /^(~)$/) {
		WriteWebHook("Sorry I do not understand that.", @parms[2]);
	}
	else {
		WriteWebHook("nil", @parms[2]);
	}
}

sub GetUserID {
	my ($username) = @_;
	sleep(0.1); # prevent flood
	my $res = `curl -s -H 'Accept: application/vnd.twitchtv.v5+json' -H 'Client-ID: $API_TWITCH' -X GET https://api.twitch.tv/kraken/users?login=$username`;
	my $decoded = decode_json($res);
	my $userID = $decoded->{'users'}[0]{'_id'} . "\n";
	return $userID;
}

sub GetGamePlaying {
	my ($userID) = @_;
	sleep(0.1); # prevent flood, create lag
	my $res = `curl -s -H 'Accept: application/vnd.twitchtv.v5+json' -H 'Client-ID: $API_TWITCH' -X GET https://api.twitch.tv/kraken/streams/$userID`; 
	$res =~ s/null/"null"/g;
	my $decoded = decode_json($res);
	my $isLive = $decoded ->{'stream'};
	my $game = $decoded ->{'stream'}{'game'};
	
	if(($isLive =~ /^(null)$/) || ($isLive =~ /^()$/)) {
		return -1;
	}
	else {
		return $game;
	}
}

sub StreamTesting {
	my @parms = @_;

	for(my $i = 0; $i < scalar(@liveStreaming); $i++) {
		if ((GetGamePlaying(GetUserID(@liveStreaming[$i])) =~ /^(-1)$/) || (GetGamePlaying(GetUserID(@liveStreaming[$i])) =~ /^$/)) {
			# offline, remove from currentLive.txt if possible
			my @currentLive = split("\n", read_file("output/currentLive.txt"));

			# they are listed as currently live, must remove since they arent
			my $str = @liveStreaming[$i];
			if($str ~~ @currentLive) {
				write_file("output/currentLive.txt", "");
				for(my $j = 0; $j < scalar(@currentLive); $j++) {
					append_file("output/currentLive.txt", @currentLive[$j] . "\n") if (@currentLive[$j] !~ /^(@liveStreaming[$i])$/);
				}
			}
		}
		else {
			my $str = @liveStreaming[$i];
			my @currentLive = split("\n", read_file("output/currentLive.txt"));
			if($str ~~ @currentLive) {
				## they have already been listed as live!!
			}
			else {
				append_file("output/currentLive.txt", @liveStreaming[$i] . "\n");
				WriteWebHook("<\@!139420334896971776> http://twitch.tv/".@liveStreaming[$i]." is now live!", @parms[0]);
			}
		}
	}
}


