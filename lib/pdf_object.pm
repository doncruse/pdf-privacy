#!/usr/bin/perl -w

package pdf_object;
use 5.006;
use strict;
use warnings;

# This is a private method. Do not call it directly.

sub new
{
  my $self = {};

  bless $self;
  return $self;
}

#FINISH ME!!!

sub to_string
{
  return "";
}

sub empty
{
  my $obj = pdf_object->new;

  $obj->{'type'} = "empty";

  return $obj;
}

# Factory method that returns a pdf_object representing a blob of text.

sub text
{
  my ($self, $pagenum, $text, $font_size) = @_;

  my $obj = pdf_object->new;

  $obj->{type} = "text";
  $obj->{text} = $text;
  $obj->{font_size} = $font_size;
  $obj->{page} = $pagenum;

  return $obj;
}

sub rect
{
  my ($self, $x, $y, $height, $width) = @_;

  my $obj = pdf_object->new;

  $obj->{type} = "rect";
  $obj->{x} = $x;
  $obj->{y} = $y;
  $obj->{height} = $height;
  $obj->{width} = $width;

  return $obj;
}

sub has_type
{
  my $self = shift;
  my $type = shift;

  return ($self->{type} eq $type);
}

return 1;
