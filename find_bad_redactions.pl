#!/usr/bin/perl

$debug = 5;

if(@ARGV != 1)
{
  print "Usage: $0 <filename>\n";
  exit;
}

$filename = $ARGV[0];

require "lib/parse_pdf_for_redactions.pl";

open(F, $filename);

my $content;

while(<F>) { $content .= $_; }

my $redactions = get_bad_redactions($content);

foreach(sort {$a <=> $b} keys(%$redactions))
{
  print "Page $_ : ".$redactions->{$_}."\n";
}

