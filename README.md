# Perl-Discord-Chat-Bot
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
