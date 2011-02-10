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
  my $self = shift;

  if($self->{type} eq 'text')
  {
    return "Text object (".$self->{x}.", ".$self->{y}.") [".
         $self->{width}." by ".$self->{height}.']: "'.$self->{text}.'"';
  }
  if($self->{type} eq 'rect')
  {
    return "Rect object (".$self->{x}.", ".$self->{y}.") [".
         $self->{width}." by ".$self->{height}."]: Some color";
  }
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
  my ($self, $pagenum, $text, $font_size, $x, $y, $width, $height) = @_;

  my $obj = pdf_object->new;

  $obj->{type} = "text";
  $obj->{text} = $text;
  $obj->{font_size} = $font_size;
  $obj->{page} = $pagenum;
  $obj->{x} = $x;

  # NOTE: This is a HUGE hack to deal with the fact that the origin of a
  # glyph is not its geometric bottom. Typical glyphs are ~25% below the "line"
  # and ~75% above it.

  $obj->{y} = $y-$height*.25;
  $obj->{height} = $height;
  $obj->{width} = $width;

  return $obj;
}

sub rect
{
  my ($self, $x, $y, $width, $height) = @_;

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
