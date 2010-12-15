package render_callback;

use 5.006;
use warnings;
use strict;
use base qw(CAM::PDF::GS);

use Dumpvalue;

our $VERSION = '1.52';

my @list;

my $pagenum;

sub init
{
  $pagenum = shift;

  @list = ();
}

sub renderText
{
  my $self = shift;
  my $string = shift;

  my $dumper = new Dumpvalue;

  my ($xu, $yu) = $self->textToUser(0, 0);
  my ($xd, $yd) = $self->userToDevice($xu, $yu);

  my $state = pdf_state->new_from_node($self, $pagenum);


  $state->process_text($string,0);

  push @list, $state->{objects}->[0];
}

sub getList
{
  return @list;
}

1;

