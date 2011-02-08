#!/usr/bin/perl

$debug = 5;

if(@ARGV != 2)
{
  print "Usage: $0 <dir_prefix> <filename>\n";
  exit;
}

$dir = $ARGV[0];
$filename = $ARGV[1];

require "lib/parse_pdf_for_redactions.pl";

open(F, $filename);

my $count = 0;

while(<F>)
{
  $count++;

  print "File #".$count."\n" if($count%20 == 0);

  chomp;
  my $filename = "$dir/$_";

  open(G, $filename);

  # print "\n$filename...\n";

  my $content = '';

  while(<G>)
  {
    $content .= $_;
  }

  my $redactions = get_bad_redactions($content);

  if(keys(%$redactions) > 0)
  {
    print "Bad redactions in $filename...\n";

    foreach(sort keys(%$redactions))
    {
      print "Page $_ : ".$redactions->{$_}."\n";
    }
  }
  else
  {
    # print "No bad redactions in $filename\n";
  }
}



