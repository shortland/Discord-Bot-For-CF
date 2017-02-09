# Perl-Discord-Chat-Bot
If you're actually interested in running your own version of this; please feel free to ask me for help since it's really incomprehensive.

Running it as is won't do much, you'll have to add custom regex for it to respond to certain keywords or messages in general. 

You can add stuff in like

    if(@parm[0] =~ /^~hello$/) {
      $myRes = "Hello there human";
    }

or

    if(@parm[0] =~ /^~help$/) {
      $myRes = "Heres a list of commands I can do: ...";
    }

and etc
