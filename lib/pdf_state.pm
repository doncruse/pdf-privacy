#!/usr/bin/perl -w

package pdf_state;
use strict;
use Dumpvalue;

require "lib/pdf_matrix.pm";

my $debug = 0;

sub new
{
  my $pagenum = shift;
  my $mediabox_ref = shift;

  my $self = {};
  my %empty_color = ();

  $self->{page} = $pagenum;
  $self->{mediabox} = $mediabox_ref;

  $self->{fill_color} = \%empty_color;
  $self->{stroke_color} = \%empty_color;

  $self->{fill_cs} = '';
  $self->{stroke_cs} = '';

  $self->{font_size} = 12;

  $self->{leading} = 0;

  $self->{trans_matrix} = pdf_matrix->new;

  $self->{text_matrix} = pdf_matrix->new;

  $self->{text} = "";
  $self->{poly} = [];

  $self->{objects} = [];

  bless $self;

  return $self;
}

sub process
{
  my $self = shift;
  my $block = shift;

  my @args = @{$block->{args}};
  my $opname = $block->{name};

  if   ($opname eq 'm')  { $self->process_m($block)     }
  elsif($opname eq 'l')  { $self->process_l($block)     }
  elsif($opname eq 'F' 
     || $opname eq 'f' 
     || $opname eq 'B' 
     || $opname eq 'B*') { $self->process_f($block)     }
  elsif($opname eq 're') { $self->process_re($block)    }
  elsif($opname eq 'cs'
     || $opname eq 'CS') { $self->process_cs($block)    }
  elsif($opname eq 'SC'
     || $opname eq 'RG'
     || $opname eq 'SCN'
     || $opname eq 'G'
     || $opname eq 'K'
     || $opname eq 'sc'
     || $opname eq 'rg'
     || $opname eq 'scn'
     || $opname eq 'g'
     || $opname eq 'k')  { $self->process_color($block) }
  elsif($opname eq 'Tf') { $self->process_tf($block)    }
  elsif($opname eq 'Td'
     || $opname eq 'TD'
     || $opname eq 'T*') { $self->process_td($block)    }
  elsif($opname eq 'Tm') { $self->process_tm($block)    }
  elsif($opname eq 'Tj'
     || $opname eq "\'"
     || $opname eq '\"') { $self->process_tj($block)    }
  elsif($opname eq 'TJ') { $self->process_capital_tj($block)    }
  else { print "Still need to handle $opname\n" }
}

sub process_m
{
  my $self = shift;
  my $block = shift;

  my @args = @{$block->{args}};

  my @coords = ($args[0]{'value'},$args[1]{'value'});
  $self->{poly} = [\@coords];

  if($debug>3)
  {
    print "Starting poly with ".poly_to_string($self->{poly})."\n";
  }
}

sub process_l
{
  my $self = shift;

  my $block = shift;

  my @args = @{$block->{args}};

  my @coords = ($args[0]{'value'},$args[1]{'value'});

  push(@{$self->{poly}}, \@coords);

  if($debug>3)
  {
    print "Added point. New poly: ".poly_to_string($self->{poly})."\n";
    print "Poly is ".@{$self->{poly}}." long\n";
  }
}

# Handles f, F, B, and B*

sub process_f
{
  my $self = shift;
  my $block = shift;

  my $opname = $block->{name};

  my $obj = get_rect_from_poly($self->{poly});

  if($obj->{type} eq 'rect')
  {
    $obj->{page} = $self->{pagenum};
    $obj->{mediabox} = $self->{mediabox};
    $obj->{fill_color} = $self->{fill_color};
    $obj->{stroke_color} = $self->{stroke_color};
    $obj->{draw_op} = $opname;

    if($debug>3)
    {
      print "f: Adding rectangle from poly\n";
    }
  }
  else
  {
    if($debug>3)
    {
      print "f: Did not add rectangle\n";
    }
  }

  $self->{poly} = [];

  my $objects_ref = $self->{objects};
  my @objects = @$objects_ref;

  push @objects, $obj;

  if(!$obj->has_type('rect'))
  {
    print "Error 1!";
  }

  $self->{objects} = \@objects;
}

# The PDF spec includes a "re" command that defines a rectangle directly.
# Here we take the four arguments of the "re" command and return a hash
# containing those elements in a more convenient format.

sub process_re
{
  my $self = shift;

  my $block = shift;

  my @args = @{$block->{args}};

  my $x = $args[0]{'value'};
  my $y = $args[1]{'value'};
  my $width = $args[2]{'value'};
  my $height = $args[3]{'value'};

  my @poly = ();

  my @coords1 = ($x,$y);
  push(@poly, \@coords1);

  my @coords2 = ($x+$width,$y);
  push(@poly, \@coords2);

  my @coords3 = ($x+$width,$y+$height);
  push(@poly, \@coords3);

  my @coords4 = ($x,$y+$height);
  push(@poly, \@coords4);

  if($debug>3)
  {
    print "Rect from re: ".poly_to_string($self->{poly})."\n";
  }

  return @poly;
}

sub process_cs
{
  my $self = shift;

  my $block = shift;

  my @args = @{$block->{args}};

  my $opname = $block->{name};

  if($opname eq 'CS')
  {
    $self->{stroke_cs} = $args[0]{'value'};
  }
  elsif($opname eq 'cs')
  {
    $self->{fill_cs} = $args[0]{'value'};
  }
}

sub process_color
{
  my $self = shift;
  my $block = shift;

  my @newargs;

  my $a;

  my %c = ();

  my $opname = lc($block->{name});

  my @args = @{$block->{args}};

  if(lc($opname) eq 'cs')
  {
    $c{'type'} = 'cs';
    $c{'name'} = $args[0]{value};
  }
  elsif(lc($opname) eq 'sc')
  {
    $c{'type'} = 'sc';
    @newargs = ();

    foreach(@args)
    {
      $a = $_->{value};
      if(defined($a))
      {
        push @newargs, $a;
      }
    }

    if(@newargs > 0)
    {
      $c{'args'} = join(",",@newargs);
    }
    else
    {
      $c{'args'} = '';
    }

    if(@newargs == 3)
    {
      # We assume that 3-arg sc colors are really rgb. This is a hack but
      # it seems to work the vast majority of the time.
      $c{'grey'} = ($newargs[0] + $newargs[1] + $newargs[2])/3;
    }

    if(@newargs == 1)
    {
      # We assume that 1-arg sc colors is really a grey value. This is a hack but
      # it seems to work the vast majority of the time.
      $c{'grey'} = $newargs[0];
    }

    $c{'cs'} = $self->{stroke_cs};
  }
  elsif(lc($opname) eq 'rg')
  {
    $c{'type'} = 'rgb';
    $c{'red'} = $args[0]{value};
    $c{'blue'} = $args[1]{value};
    $c{'green'} = $args[2]{value};

    $c{'grey'} = 0.3*$c{'red'} + 0.59*$c{'green'} + 0.11*$c{'blue'};
  }
  elsif(lc($opname) eq 'scn')
  {
    $c{'type'} = 'scn';
    @newargs = ();

    foreach(@args)
    {
      $a = $_->{value};
      if(defined($a))
      {
        push @newargs, $a;
      }
    }

    if(@newargs > 0)
    {
      $c{'args'} = join(",",@newargs);
    }
    else
    {
      $c{'args'} = '';
    }

    if(@newargs == 3)
    {
      # We assume that 3-arg scn colors are really rgb. This is a hack but
      # it seems to work the vast majority of the time.
      $c{'grey'} = ($newargs[0] + $newargs[1] + $newargs[2])/3;
    }
    if(@newargs == 1)
    {
      # We assume that 1-arg scn colors is really a grey value. This is a hack but
      # it seems to work the vast majority of the time.
      $c{'grey'} = $newargs[0];
    }


    $c{'cs'} = $self->{stroke_cs};
  }
  elsif(lc($opname) eq 'g')
  {
    $c{'type'} = 'grey';

    $c{'grey'} = $args[0]{value};
  }
  elsif(lc($opname) eq 'k')
  {
    $c{'type'} = 'cymk';
    $c{'cyan'} = $args[0]{value};
    $c{'yellow'} = $args[1]{value};
    $c{'magenta'} = $args[2]{value};
    $c{'black'} = $args[3]{value};
  }

  if($opname eq lc($opname))
  {
    $self->{fill_color} = \%c
  }
  else
  {
    $self->{stroke_color} = \%c
  }
}

sub process_tf
{
  my $self = shift;

  my $block = shift;

  my @args = @{$block->{args}};

  if(@args == 2 && $args[-1]->{type} eq 'number')
  {
    $self->{font_size} = $args[-1]->{value};
  }
  else
  {
    my $n = @args;
    my $type = $args[-1]->{type};

    print "Error! n is $n, type is $type\n";
  }
}

sub process_td
{
  my $self = shift;

  my $block = shift;

  my @args = @{$block->{args}};

  my $opname = $block->{name};

  if(($opname eq 'Td' || $opname eq 'TD') && @args != 2)
  {
    print "Error! $opname with ".@args." arguments instead of 2.\n";
  }
  elsif($opname eq 'T*' && @args != 0)
  {
    print "Error! T* with ".@args." arguments instead of 0.\n";
  }
  else
  {
    if($opname eq 'TD')
    {
      # FINISH ME! Is this right?
      $self->{leading} = 0-($args[1]->{value});
    }

    if($self->{text} ne '')
    {
      my $objects_ref = $self->{objects};
      my @objects = @$objects_ref;

      my $obj = pdf_object->text(
          $self->{page},
          $self->{text}, 
          $self->{font_size});

      push @objects, $obj;

      if(!$obj->has_type('text'))
      {
        print "Error 2!";
      }

      $self->{objects} = \@objects;

      $self->{text} = '';
    }

    my $tx;
    my $ty;

# FINISH ME!!!
#    if($opname eq 'TD' || $opname eq 'Td')
#    {
#      $tx = $args[0]->{value};
#      $ty = $args[1]->{value};
#    }
#    elsif($opname eq 'T*')
#    {
#      $tx = 0;
#      $ty = $current_leading;
#
#    }
#    else
#    {
#      die "Error: failed to deal with $opname!";
#    }
#
#    $current_x += $tx;
#    $current_y += $ty;
#
#    $current_xscale = 1;
#    $current_yscale = 1;
  }
}

sub process_tm
{
  my $self = shift;

  my $block = shift;

  my @args = @{$block->{args}};

  if(@args != 6)
  {
    print "Error! Tm with ".@args." arguments instead of 6.\n";
  }
  elsif($args[1]->{value} != 0 || $args[2]->{value} != 0)
  {
    print "Warning: found non-horizontal text:";
    print "(".$args[0]->{value}.", ".
              $args[1]->{value}.", ".
              $args[2]->{value}.", ".
              $args[3]->{value}.") Ignoring.\n";
  }
  else
  {
    if($self->{text} ne '')
    {
      my $objects_ref = $self->{objects};
      my @objects = @$objects_ref;

      my $obj = pdf_object->text(
          $self->{page},
          $self->{text}, 
          $self->{font_size});

      push @objects, $obj;

      if(!$obj->has_type('text'))
      {
        print "Error 3!";
      }

      $self->{objects} = \@objects;

      $self->{text} = '';
    }

    # FINISH ME!!!
    #$current_xscale = $args[0]->{value};
    #$current_yscale = $args[3]->{value};
    # I think this is wrong.
    #$current_x = $args[4]->{value};
    #$current_y = $args[5]->{value};
  }
}

sub process_tj
{
  my $self = shift;

  my $block = shift;

  my @args = @{$block->{args}};

  if (@args >= 1
      && ($args[-1]->{type} eq 'string'
          || $args[-1]->{type} eq 'hexstring'))
  {
    my $hash_ref = $args[-1];

    $self->{text} .= $args[-1]->{'value'};
  }
}

sub process_capital_tj
{
  my $self = shift;

  my $block = shift;

  my @args = @{$block->{args}};

  if (@args == 1 && $args[0]->{type} eq 'array')
  {
    my $s = '';

    my @strings = @{$args[0]->{value}};

    foreach my $element (@strings)
    {
      if ($element->{type} eq 'string' || $element->{type} eq 'hexstring')
      {
        $self->{text} .= $element->{'value'};
      }
      elsif ($element->{type} eq 'number')
      {
        # We might want to do something here some day.
      }
    }
  }
}

sub get_final_text
{
  my $self = shift;

  if($self->{text} ne '')
  {
    my $objects_ref = $self->{objects};
    my @objects = @$objects_ref;

    my $obj = pdf_object->text(
        $self->{page},
        $self->{text}, 
        $self->{font_size});

    if($obj->has_type('text'))
    {
      push @objects, $obj;
      $self->{objects} = \@objects;
    }

    $self->{text} = '';
  }

  return '';
}

# The PDF spec gives us at least two ways to define a rectangle: with the "re"
# commend, or with a series of "m" and "l" commands. In the latter case, we
# need to collect the points and then analyze them to see if they constitute
# a rectangle. This function will return a "rect" data structure if the polygon
# constitutes a rectangle. Otherwise it will return a hash with the
# 'is_rect' value set to 0.

sub get_rect_from_poly
{
  # We bail by returning a ref to %rect, which by default will be flagged
  # as not a well-formed rectangle.

  my $poly_ref = shift;

  my @poly = @$poly_ref;

  my $length = @poly;

  # A rectangle has four vertices. We'll accept a 5-vertex polygon if
  # the first and last vertex are the same. Otherwise, we give up.

  if($length<4 || $length >5)
  {
    return pdf_object->empty;
  }

  # Each vertex is a two-element array (x,y)

  my $v0_ref = $poly[0];
  my @v0 = @$v0_ref;

  my $v1_ref = $poly[1];
  my @v1 = @$v1_ref;

  my $v2_ref = $poly[2];
  my @v2 = @$v2_ref;

  my $v3_ref = $poly[3];
  my @v3 = @$v3_ref;

  if($length == 5)
  {
    my $v4_ref = pop @poly;
    my @v4 = @$v4_ref;

    # If the polygon has five vertices and the first and fifth aren't the
    # same, then it's not a rectangle.

    if($v0[0] != $v4[0] || $v0[1] != $v4[1])
    {
      return pdf_object->empty;
    }
  }

  # We want the first line to be vertical. If it's horizontal, rotate
  # the vertex to the end.

  if($v0[1] == $v1[1])
  {
    my @t = @v0;
    @v0 = @v1;
    @v1 = @v2;
    @v2 = @v3;
    @v3 = @t;
  }

  my $width = abs($v0[0]-$v2[0]);
  my $height = abs($v0[1]-$v2[1]);

  # We don't want to reject rectangles that are slightly off-rectangular,
  # since this might simply be a result of bad floating point arithmetic.

  my $tol = (abs($width) + abs($height))/1000;

  return pdf_object->empty if($tol == 0);

  # First and third edges should be vertical, second and fourth horizontal.

  return pdf_object->empty if(abs($v0[0]-$v1[0])>$tol);
  return pdf_object->empty if(abs($v1[1]-$v2[1])>$tol);
  return pdf_object->empty if(abs($v2[0]-$v3[0])>$tol);
  return pdf_object->empty if(abs($v3[1]-$v0[1])>$tol);
  # Make sure the rectangle has non-zero width

  return pdf_object->empty if($v0[0] == $v2[0]);
  return pdf_object->empty if($v0[1] == $v2[1]);

  my $x = min($v0[0], $v2[0]);
  my $y = min($v0[1], $v2[1]);

  return pdf_object->rect($x, $y, $height, $width);
}

# Takes a list of points (which are references to 2-element arrays)
# and prints them in a nice format.

sub poly_to_string
{
  my @poly = @_;

  my @points = ();

  foreach(@poly)
  {
    push(@points, "(".join(", ", @$_).")");
  }

  return "[".join(", ",@points)."]";
}

sub get_objects_with_type
{
  my $self = shift;
  my $type = shift;

  my @objects = ();

  my $objects_ref = $self->{objects};

  foreach my $obj (@$objects_ref)
  {
    my $dumper = new Dumpvalue;
    #$dumper->dumpValue($obj);

    if($obj->has_type($type))
    {
      push @objects, $obj;
    }
  }

  return \@objects;
}

sub get_rects
{
  my $self = shift;

  return $self->get_objects_with_type('rect');
}

sub get_texts
{
  my $self = shift;

  return $self->get_objects_with_type('text');
}

return 1;

