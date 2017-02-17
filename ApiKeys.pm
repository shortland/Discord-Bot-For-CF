#!/usr/bin/perl

package ApiKeys;

use Exporter;

our @ISA = qw(Exporter);

#can be
our @EXPORT_OK = qw($API_TWITCH $API_YANDEX $API_AI $API_DISCORD);
#default
our @EXPORT = qw($API_TWITCH $API_YANDEX $API_AI $API_DISCORD);

$API_YANDEX = "";
$API_DISCORD = "";
$API_TWITCH = "";
$API_AI = "";

1;