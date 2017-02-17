#!/usr/bin/perl

package TextEscape;

use Exporter;

our @ISA = qw(Exporter);

#can be
our @EXPORT_OK = qw(DiscordEscape cURLEscape);
#default
our @EXPORT = qw(DiscordEscape cURLEscape);

sub DiscordEscape {
	my @parms = @_;
	#parms[0] = string to escape
	@parms[0] =~ s/\(/\(/g;
	@parms[0] =~ s/\)/\)/g;
	@parms[0] =~ s/'/\\'/g;
	@parms[0] =~ s/"/\\"/g;
	@parms[0] =~ s/\n/\\n/g;
	@parms[0] =~ s/\t/\\t/g;
	return @parms[0];
}

sub cURLEscape {
	my @parms = @_;
	#parms[0] = string to escape
	@parms[0] =~ s/'/\'\\\'\'/g;
	@parms[0] =~ s/"/\\\"/g;
	@parms[0] =~ s/\(/\\\(/g;
	@parms[0] =~ s/\)/\\\)/g;
	@parms[0] =~ s/\n/\\n/g;
	@parms[0] =~ s/\t/\\t/g;
	return @parms[0]
}

1;