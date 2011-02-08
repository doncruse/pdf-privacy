#!/usr/bin/perl

$debug = 5;

if(@ARGV != 2)
{
  print "Usage: $0 <input_file> <output_file>\n";
  exit;
}

$filename = $ARGV[0];
$results = $ARGV[1];

require "lib/parse_pdf_for_redactions.pl";

open(F, $filename);

open(OUT, ">$results");

my $count = 0;

while(<F>)
{
  $filename = $_;
  $count++;

  print "File #".$count."\n" if($count%20 == 0);

  chomp;

  my $path = get_path_from_filename($filename);

  open(G, $path);

  my $content = '';

  while(<G>)
  {
    $content .= $_;
  }

  my $redactions = get_bad_redactions($content);

  if(keys(%$redactions) > 0)
  {
    print OUT $filename;
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

sub get_path_from_filename
{
  my ($filename) = @_;

  my ($gov,$uscourts,$court,$case,$doc,$subdoc,$extension) 
    = split(/\./,$filename);

  return "/n/fs/recap/pacer/$court/$case/$filename";

}

