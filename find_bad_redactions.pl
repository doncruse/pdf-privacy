#!/usr/bin/perl

$debug = 5;

$filename = $ARGV[0];

require "lib/parse_pdf_for_redactions.pl";

open(F, $filename);

my $content;

while(<F>) { $content .= $_; }

my $redactions = get_bad_redactions($content);

foreach(sort keys(%$redactions))
{
  print "Page $_ : ".$redactions->{$_}."\n";
}

