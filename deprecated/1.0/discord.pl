#!/usr/bin/env perl

use JSON;
use File::Slurp;
use URI::Encode qw(uri_encode uri_decode);
use Try::Tiny;
use MIME::Base64;
#use open ':std', ':encoding(UTF-8)'; # removes wideprint error
use AnyEvent::WebSocket::Client;
use Math::Round;

use CGI;
BEGIN {
	$cgi = new CGI;
	print $cgi->header(-type => "text");
	open(STDERR, ">&STDOUT");
}

our $BALANCEVERSION = "3.3sv";

our @webhooks;
our $runTime = 0;
our $BotNameCall = "";

our @league = ("BRONZE", "SILVER", "GOLD", "PLATINUM", "DIAMOND", "MASTER", "GRANDMASTER");
our @race = ("TERRAN", "ZERG", "PROTOSS", "RANDOM");
our @raceEmojies = ("<:TERRAN:278762425552207883>", "<:ZERG:278762452265467907>", "<:PROTOSS:278762398347689984>", "<:RANDOM:278762354001444864>");
our @emojies = ("<:BRONZE3:278725418641522688>", "<:SILVER2:278725418813751297>", "<:GOLD1:278725419073536012>", "<:PLATINUM1:278725419056758784>", "<:DIAMOND1:278725418960551937>", "<:MASTER1:278725418679271425>", "<:GRANDMASTER:278725419186782208>");
our @clanTags = ("CONFED", "CONFD", "XCFX");

our $DISCORDAPI = "";
our $DAVID = read_file("david.txt");
our $translateApiKey = "";
our $apiAIKey = "";
our $twitchAPIKey = "";

our @liveStreaming = split("\n", read_file("streamers.txt"));

our $serverList = `curl -s -A "DiscordBot (http://ilankleiman.com, 4.0.0)" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bot $DISCORDAPI" "https://discordapp.com/api/users/\@me/guilds" -L`;
$serverList = decode_json($serverList);

GetAndMakeHooks(MyBotName());

sub MakeDiscordRequest {
	my @parms = @_;
	#parms[0] = endpoint /users/\@me
	#parms[1] = 
	#parms[2] = return decoded json, 0=no, 1=yes
	my $userAgent = "DiscordBot (http://ilankleiman.com, 4.0.0)";
	my $contentType = "Content-Type: application/x-www-form-urlencoded";
	my $authorizeCode = "Authorization: Bot $DISCORDAPI";
	my $baseURL = "https://discordapp.com/api";
	my $response = `curl -s -A "$userAgent" -H "$contentType" -H "$authorizeCode" "${baseURL}@{parms[0]}" -L`;
	return $response;
}

sub MyBotNameIf {
	if ((!defined $BotNameCall) || ($BotNameCall =~ /^$/)) {
		print "Have to create new instance of name";
		$BotNameCall = MyBotName();
		return $BotNameCall;
	}
	else {
		return $BotNameCall;
	}
}

sub MyBotName {
	my @parms = @_;
	my $response = `curl -s -A "DiscordBot (http://ilankleiman.com, 4.0.0)" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bot $DISCORDAPI" "https://discordapp.com/api/users/\@me" -L`;
	$response = decode_json($response);
	my $name = $response->{'username'};
	return $name;
}

sub WriteWebHook {
	my @parms = @_;
	for(my $j = 0; $j < scalar(@webhooks); $j++) {
		if(!defined @parms[0] || !defined @parms[1] || @parms[0] =~ /^nil$/) {
			#print "No message defined";
			last;
		}
		elsif (length(@parms[0]) >= 2000) {
			WriteWebHook("Message limit is not allowed to exceed 2000 characters", @parms[1]);
			last;
		}
		else {
			my @words = split / /, @webhooks[$j];
			if (@words[0] =~ /^@parms[1]$/) {
				#print @parms[0];
				if(@parms[2] =~ /^base64$/) {
					@parms[0] = decode_base64(@parms[0]);
					#@parms[0] = uri_encode(@parms[0]);
					@parms[0] =~ s/\(/\(/g;
					@parms[0] =~ s/\)/\)/g;
					@parms[0] =~ s/'/\'\\\'\'/g;
					@parms[0] =~ s/"/\\\"/g;
					@parms[0] = "`".@parms[0] . "`";
					print @parms[0];
				}
				print $postMessage = `curl -s -A "DiscordBot (http://ilankleiman.com, 4.0.0)" -H "Content-Type: application/json" -X POST -d '{"content" : "@parms[0]"}' -H "Authorization: Bot $DISCORDAPI" "https://discordapp.com/api/webhooks/@words[1]/@words[2]" -L`;
			}
			else {
				#print @words[0]."VS>".@parms[1]."<<";
			}
		}
	}
}

sub GetAndMakeHooks {
	my @parms = @_;
	for(my $i = 0; $i < scalar(@{$serverList}); $i++) {
		my $webhookList = `curl -s -A "DiscordBot (http://ilankleiman.com, 4.0.0)" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bot $DISCORDAPI" "https://discordapp.com/api/guilds/$serverList->[$i]{'id'}/webhooks" -L`;
		$webhookList = decode_json($webhookList);
		@webhooks = ();
		for(my $j = 0; $j < scalar(@{$webhookList}); $j++) {
			if($webhookList->[$j]{'name'} =~ /^(@parms[0])$/) {
				@webhooks[$j] = $webhookList->[$j]{'channel_id'};
			}
			else {
				#print "not " . $webhookList->[$j]{'name'} . " end not\n";
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
					`curl -s -H "Content-Type: application/json" -X POST -d '{"name":"@parms[0]", "avatar" : "$DAVID"}' -A "DiscordBot (ilankleiman.com, 4.0.0)" -H "Authorization: Bot $DISCORDAPI" "https://discordapp.com/api/channels/$channelID/webhooks" -L`;
				}
			}
		}
		$webhookList = `curl -s -A "DiscordBot (http://ilankleiman.com, 4.0.0)" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bot $DISCORDAPI" "https://discordapp.com/api/guilds/$serverList->[$i]{'id'}/webhooks" -L`;
		$webhookList = decode_json($webhookList);
		@webhooks = ();
		for(my $j = 0; $j < scalar(@{$webhookList}); $j++) {
			if($webhookList->[$j]{'name'} =~ /^(@parms[0])$/) {
				@webhooks[$j] = $webhookList->[$j]{'channel_id'} . " " . $webhookList->[$j]{'id'} . " " . $webhookList->[$j]{'token'};
			}
		}
	}
	GetChannels($serverList);
}

sub GetChannels {
	my @parms = @_;

	my $listed = @parms[0];
	#print $listed->[0]{'id'}."]";
	for(my $i = 0; $i < scalar(@{$listed}); $i++) {
		my $channelList = `curl -s -A "DiscordBot (http://ilankleiman.com, 4.0.0)" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bot $DISCORDAPI" "https://discordapp.com/api/guilds/$listed->[$i]{'id'}/channels" -L`;
		my $channelListed = $channelList;
		$channelListed =~ s/\(/\(/g;
		$channelListed =~ s/\)/\)/g;
		$channelListed =~ s/'/\'\\\'\'/g;
		$channelListed =~ s/"/\\\"/g;
		try {
			$channelListed = decode_json($channelList);
		} 
		catch {
			print "$channelList \n";
			print "Error decoding json : $_\n";
		};
		for(my $j = 0; $j < scalar(@{$channelListed}); $j++) {
			if(($channelListed->[$j]{'type'} ~~ "text")) {
				my $channelID = $channelListed->[$j]{'id'};
				ReadChannel($channelID);
				if($runTime > 60) {
					`./inOnline.pl`
					my $channelData = `curl -s -A "DiscordBot (http://ilankleiman.com, 4.0.0)" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bot $DISCORDAPI" "https://discordapp.com/api/channels/$channelID" -L`;
					my $decodedChannel;
					try {
						$decodedChannel = decode_json($channelData);
					}
					catch {
						print "Error decoding json : $_\n";
					};
					if(lc($decodedChannel->{'name'}) =~ /^(streams|streaming)$/) {
						StreamTesting($channelID);
					}
				}
			}
		}
	}
	$runTime += 2;
	sleep(1.5);
	if($runTime > 90) {
		print time . "\n";
		my $count = read_file("isdie.txt");
		$count++;
		write_file("isdie.txt", $count);
		#CheckStreaming();
		$runTime = 0;
	}
	return GetChannels(@parms[0]);
}

sub GetLeagueNumber {
	my @parms = @_;
	for(my $i = 0; $i < 7; $i++) {
		if(@parms[0] =~ /^@league[$i]$/) {
			$leagueNum = $i;
			last;
		}
	}
	return @emojies[$leagueNum];
}

sub GetRaceNumber {
	my @parms = @_;
	for(my $i = 0; $i < 4; $i++) {
		if(@parms[0] =~ /^@race[$i]$/) {
			$racenum = $i;
			last;
		}
	}
	return @raceEmojies[$racenum];
}

## deprecated
# sub PostMessage {
# 	my @parms = @_;
# 	if(!defined @parms[0] || !defined @parms[1] || @parms[0] =~ /^nil$/) {
# 		return "No message defined";
# 	}
# 	elsif (length(@parms[0]) >= 4000) {
# 		return "Message limit is not allowed to exceed 4000 characters";
# 	}
# 	else {
# 		my $postMessage = `curl -s -A "Discord/59 CFNetwork/808.2.16 Darwin/16.3.0" -H "Content-Type: application/json" -H "Cookie: __cfduid=x" -H "Authorization: d" -H "x-super-properties: x" -X POST -d '{"content":"@parms[0]","nonce":"278276808804139008","tts":false}' "https://discordapp.com/api/v6/channels/@parms[1]/messages"`;
# 		return $postMessage;
# 	}
# }

sub ReadChannel {
	my @parms = @_;
	our $processed = read_file("innovation.txt");
	our @readMessages = split /\n/, $processed;

	if(defined @parms[0]) {
		my $getMessage = `curl -s -A "DiscordBot (http://ilankleiman.com, 4.0.0)" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bot $DISCORDAPI" "https://discordapp.com/api/channels/@parms[0]/messages?limit=6" -L`;
		my $decodedMessage;
		try {
			$decodedMessage = decode_json($getMessage);
		} 
		catch {
			print "Error reading channel json\n";
			return;
		};
		#print "yes";
		if (defined($decodedMessage)) {
			#print "yes";
			for(my $i = 0; $i < scalar(@{$decodedMessage}); $i++) {
				#print "looping through";
				#print "Looping through them all " . $i . "\n";
				my $user = uri_encode($decodedMessage->[$i]{'author'}{'username'});
				my $attachments = $decodedMessage->[$i]{'attachments'}[0]{'url'};
				my $myName = MyBotNameIf();
				$myName =~ s/ /\%20/g;
				if($user =~ /^($myName)$/i) {
					next;
				}
				else 
				{
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
						append_file("innovation.txt", $messageID."\n");

						if ($attachments =~ /SC2Replay/) {
							#download it
							print "is attachment type replay\n";
							`curl -s "$attachments" >output/testing.SC2Replay`;
							# $replayData = qx("./parse.pl");
							# print ">>".$replayData;
							# #sleep(0.5);
							# #$replayData =~ s/\\n/\\\\n/g;
							
							`./parse.pl`;
							$balance = read_file("output/balance.txt");
							$balance =~ s/\n/\\\\n/g;
							WriteWebHook("`".$balance."\\nMUCH BALANCE!!!`", @parms[0]);
						}

						ParseMessage(lc($messageContent), $user, @parms[0]);
					}
					else {
						#print "It's been found before. Don't do stuff\n";
					}
				}
			}
		}
	}
}

sub ParseMessage {
	my @parms = @_;
	my $myRes;

	#print "parsing got " . @parms[0];
	# message too short to comprehend.
	if (length(@parms[0]) <= 1) {
		WriteWebHook("nil", @parms[2]);
	}
	elsif (@parms[0] =~ /^(~ping)$/i) {
		WriteWebHook("pong", @parms[2]);
	}
	elsif (@parms[0] =~ /^(~help)$/i) {
		my $help = read_file("help.txt");
		$help =~ s/\n/\\n/g;
		WriteWebHook($help, @parms[2]);
	}
	elsif ((index(@parms[0], "~roster") != -1) && (substr(@parms[0], 0, 1) =~ /^(~)$/) ){
		#print "im doing parse";
		my $data = `curl -s "http://ilankleiman.com/JoinMembers.php"`;
		$data = decode_json($data);

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

					if (uc(@searchParms[1]) ~~ @league) {
						$realL = uc($data->[$i]{'league'});
					}
					elsif (uc(@searchParms[1]) ~~ @race) {
						$realL = uc($data->[$i]{'race'});
					}
					elsif (uc(@searchParms[1]) ~~ @clanTags) {
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
			$j++
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

		my $apiKey = $translateApiKey;
		my $response = `curl -s -X POST -H "Content-Type: application/x-www-form-urlencoded" "https://translate.yandex.net/api/v1.5/tr.json/translate?lang=$fromLanguage-$toLanguage&key=$apiKey" -d "text=$content"`;
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
			$streamers = read_file("streamers.txt");
			$streamers =~ s/\n/\\n/g;
			WriteWebHook("Streams I check:\\n" . $streamers, @parms[2]);
		}
		elsif($type =~ /^live$/) {
			$streamers = read_file("currentLive.txt");
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
		my $clever = `curl -s -H "Authorization: Bearer $apiAIKey" "https://api.api.ai/v1/query?v=20150910&query=$query&lang=en&sessionId=1234567890"`;

		my $deClever = decode_json($clever);
		my $cleverRes = $deClever->{'result'}{'fulfillment'}{'speech'};

		$myRes = $cleverRes;
		$myRes =~ s/'//g;
		WriteWebHook($myRes, @parms[2]);
	}
	# elsif ((index(@parms[0], "~reboot") != -1) && (substr(@parms[0], 0, 1) =~ /^(~)$/) ){
	# 	WriteWebHook("Whole reboot may take up to 5 minutes. Plz dont use unless necessary", @parms[2]);
	# 	#`echo 'FreeSteveo123!' | sudo -S reboot`;
	# }
	elsif ((substr(@parms[0], 0, 1) =~ /^(~)$/) && (substr(@parms[0], 1, 1) =~ /^(c)$/)) {
		# @parms[0] =~ s/\~c //g;
		# my $resolved = `@parms[0]`;
		# if($resolved =~ /^$/) {
		# 	$resolved = "Error doing that! ".$resolved;
		# }
		# $resolved =~ s/\n/\\n/g;
		# $resolved =~ s/\t/    /g;
		# print $resolved = encode_base64($resolved);
		# $resolved =~ s/\n//g;
		# WriteWebHook($resolved, @parms[2], "base64");
		WriteWebHook("Sorry that command is disabled.", @parms[2]);
	}
	elsif(substr(@parms[0], 0, 1) =~ /^(~)$/) {
		WriteWebHook("Sorry I do not understand that.", @parms[2]);
	}
	else {
		WriteWebHook("nil", @parms[2]);
	}
}

sub CheckStreaming {
	my @parms = @_;
	print "CHECKING FOR ACTIVE STREAMERS\n";
	my $streamerList = read_file("streamers.txt");
	my @streamers = split /\n/, $streamerList;
	for (my $i = 0; $i < scalar(@streamers); $i++) {
		if (GetGamePlaying(GetUserID(@streamers[$i])) =~ /^(-1)$/) { }
		else {
			print "https://twitch.tv/" . @streamers[$i] . " has started streaming " . GetGamePlaying(GetUserID(@streamers[$i]));
		}
	}
}

sub GetUserID {
	my ($username) = @_;
	my $res = `curl -s -H 'Accept: application/vnd.twitchtv.v5+json' -H 'Client-ID: $twitchAPIKey' -X GET https://api.twitch.tv/kraken/users?login=$username`;
	my $decoded = decode_json($res);
	my $userID = $decoded->{'users'}[0]{'_id'} . "\n";
	return $userID;
}

sub GetGamePlaying {
	my ($userID) = @_;
	my $res = `curl -s -H 'Accept: application/vnd.twitchtv.v5+json' -H 'Client-ID: $twitchAPIKey' -X GET https://api.twitch.tv/kraken/streams/$userID`; 
	$res =~ s/null/"null"/g;
	my $decoded = decode_json($res);
	my $isLive = $decoded ->{'stream'};
	my $game = $decoded ->{'stream'}{'game'};
	
	if($isLive =~ /^(null)$/) {
		return -1;
	}
	else {
		return $game;
	}
}

sub StreamTesting {
	my @parms = @_;

	for(my $i = 0; $i < scalar(@liveStreaming); $i++) {
		if(GetGamePlaying(GetUserID(@liveStreaming[$i])) =~ /^(-1)$/) {
			# offline, remove from currentLive.txt if possible
			my @currentLive = split("\n", read_file("currentLive.txt"));

			# they are listed as currently live, must remove since they arent
			my $str = @liveStreaming[$i];
			if($str ~~ @currentLive) {
				#append_file("channelDatas.txt", @liveStreaming[$i] . " is NOT live rn!");
				write_file("currentLive.txt", "");
				for(my $j = 0; $j < scalar(@currentLive); $j++) {
					append_file("currentLive.txt", @currentLive[$j] . "\n") if (@currentLive[$j] !~ /^(@liveStreaming[$i])$/);
				}
			}
		}
		else {
			my $str = @liveStreaming[$i];
			my @currentLive = split("\n", read_file("currentLive.txt"));
			if($str ~~ @currentLive) {
				## they have already been listed as live!!
			}
			else {
				append_file("currentLive.txt", @liveStreaming[$i] . "\n");
				append_file("channelDatas.txt", @liveStreaming[$i] . " is live rn!");
				WriteWebHook("<\@!139420334896971776> http://twitch.tv/".@liveStreaming[$i]." is now live!", @parms[0]);
			}
		}
	}
}

# check if widget exists 
# if not, make it :
# PATCH https://discordapp.com/api/v6/guilds/147698382092238848/embed
# {"enabled":false,"channel_id":"1234567890"}
# Authorization: your token
# Content-Type: application/json

# ok so now we have widget.
# get list of online members through the widget json



