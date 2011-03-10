#!/usr/bin/perl -w

use CAM::PDF;
use CAM::PDF::Content;

if(@ARGV != 1)
{
  print "Usage: $0 <filename>\n";
  exit;
}

my $filename = $ARGV[0];

my $output_filename;

if($filename =~ /^(.*)\.pdf$/)
{
  $output_filename = $1.".norects.pdf";
}
else
{
  print "Error: filename must end in .pdf\n";
  exit;
}

require "lib/strip_polygons.pl";

open(F, $filename);

my $content;

while(<F>) { $content .= $_; }

my $pdf = CAM::PDF->new($content) || return ();

my $pages = $pdf->numPages();

my $error;

for(my $pagenum = 1; $pagenum <=$pages; $pagenum++)
{
  my $pagetree;
  eval
  {
    $pagetree = $pdf->getPageContentTree($pagenum)
  };

  if($error = $@)
  {
    warn "Caught error: $error";
  }
  else
  {
    my $new_pagetree = strip_polygons($pagetree);
    $pdf->setPageContent($pagenum, $new_pagetree->toString());
  }
}

$pdf->cleanoutput($output_filename);

