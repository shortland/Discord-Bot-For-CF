#!/usr/bin/perl

use JSON;
use File::Slurp;

`python -m spawningtool output/testing.SC2Replay --cache-dir output/`;

opendir DIR, "output" or die "cannot open dir 'output': $!";
my @file = readdir DIR;
closedir DIR;

my @noHide;
my $opFile;
for(my $i = 0; $i < scalar(@file); $i++) {
	if(@file[$i] =~ /\./) { }
	else {
		$opFile = @file[$i];
	}
}

my $json = read_file("output/$opFile");
my $data = decode_json($json);

my $text = "";
$text .= "". $data->{'map'} . " " . $data->{'game_type'} . "\\n";
$text .= "About ".int((($data->{'frames'})/16)/60) . " minutes long\\n";
$text .= "". $data->{'players'}{1}{'name'} . " (" .$data->{'players'}{1}{'race'}. ") vs " .$data->{'players'}{2}{'name'} . " (" .$data->{'players'}{2}{'race'}. ")\\n";
$text .= "". $data->{'players'}{1}{'name'} . " won!\n" if($data->{'players'}{1}{'is_winner'});
$text .= "". $data->{'players'}{2}{'name'} . " won!\n" if($data->{'players'}{2}{'is_winner'});


my $errors;
while ($_ = glob('output/* output/.*')) {
   next if -d $_;
   unlink($_)
      or ++$errors, warn("Can't remove $_: $!");
}
exit(1) if $errors;


write_file("output/balance.txt", "$text");

print $text;