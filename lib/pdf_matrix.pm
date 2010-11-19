#!/usr/bin/perl -w

package pdf_matrix;
use 5.006;
use strict;
use warnings;
use Data::Dumper;

use List::Util qw[min max];

require 'dumpvar.pl';

sub new
{
  my $self = {};
  if(@_ == 1)
  {
    my $matrix = [[1,0,0], [0,1,0], [0,0,1]];
    $self->{matrix} = $matrix;
  }
  elsif(@_ == 2)
  {
    my ($proto, $matrix) = @_;
    $self->{matrix} = $matrix;
  }
  else
  {
    my ($proto, $a, $b, $c, $d, $e, $f) = @_;

    my $matrix = [[$a,$b,0], [$c,$d,0], [$e,$f,1]];
    $self->{matrix} = $matrix;
  }

  bless $self;
  return $self;
}

sub multiply
{
  my $self = shift;
  my $other = shift;

  my $result = [[0,0,0],[0,0,0],[0,0,0]];

  for(my $i = 0; $i < 3; $i++)
  {
    for(my $j = 0; $j < 3; $j++)
    {
      for(my $k = 0; $k < 3; $k++)
      {
        $result->[$i]->[$j] += $self->{matrix}->[$i]->[$k] *
                              $other->{matrix}->[$k]->[$j];
      }
    }
  }

  return new pdf_matrix($result);
}

sub to_string
{
  my $self = shift;

  my $matrix = $self->{matrix};
  my @lines = ();

  foreach(@$matrix)
  {
    push @lines, join(", ", @$_);
  }

  return "[".join("]\n[", @lines)."]\n";
}

return 1;
