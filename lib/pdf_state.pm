#!/usr/bin/perl -w

package pdf_state;
use strict;
use Dumpvalue;

use List::Util qw[min max];

require "lib/pdf_matrix.pm";

my $debug = 0;

sub new
{
  my $proto = shift;
  my $page = shift;
  my $mediabox_ref = shift;

  my $self = {};
  my %empty_color = ();

  $self->{page}         = $page;
  $self->{mediabox}     = $mediabox_ref;
  $self->{fill_color}   = \%empty_color;
  $self->{stroke_color} = \%empty_color;
  $self->{fill_cs}      = '';
  $self->{stroke_cs}    = '';
  $self->{poly}         = [];
  $self->{objects}      = [];
  $self->{ct_matrix}    = pdf_matrix->new;

  bless $self;

  $self->start_text_block;
  return $self;
}

# Called in response to a "BT" command.

sub start_text_block
{
  my $self = shift;

  $self->{line_matrix} = pdf_matrix->new;
  $self->{text_matrix} = pdf_matrix->new;
  $self->{text}         = "";
  $self->{hoffset}      = 0;
  $self->{char_spacing} = 0;
  $self->{word_spacing} = 0;
  $self->{font_size}    = 12;
  $self->{leading}      = 0;
  $self->{hscale}       = 1;
}

sub process
{
  my $self = shift;
  my $block = shift;
  my $opname = $block->{name};

#  print "\n\n\n----------\n\n\n";
#
#  my $dumper = new Dumpvalue;
#  $dumper->dumpValue($block);

  if   ($opname eq 'm')  { $self->process_m($block)     }
  elsif($opname eq 'l')  { $self->process_l($block)     }
  elsif($opname eq 'h')  { $self->process_h($block)     }
  elsif($opname eq 'F')  { $self->process_cap_f($block) }
  elsif($opname eq 'f')  { $self->process_f($block)     }
  elsif($opname eq 'f*') { $self->process_f_star($block)}
  elsif($opname eq 'B')  { $self->process_b($block)     }
  elsif($opname eq 'B*') { $self->process_b_star($block)}
  elsif($opname eq 're') { $self->process_re($block)    }
  elsif($opname eq 'cs') { $self->process_cs($block)    }
  elsif($opname eq 'CS') { $self->process_cap_cs($block)}
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
  elsif($opname eq 'cm') { $self->process_cm($block)    }
  elsif($opname eq 'n')  { $self->process_n($block)     }
  elsif($opname eq 'W')  { $self->process_cap_w($block) }
  elsif($opname eq 'W*') { $self->process_w_star($block)}
  elsif($opname eq 'w')  { $self->process_w($block)     }
  elsif($opname eq 'S')  { $self->process_cap_s($block) }
  elsif($opname eq 's')  { $self->process_s($block)     }
  elsif($opname eq 'Tf') { $self->process_tf($block)    }
  elsif($opname eq 'TL') { $self->process_tl($block)    }
  elsif($opname eq 'Td') { $self->process_td($block)    }
  elsif($opname eq 'TD') { $self->process_cap_td($block)}
  elsif($opname eq 'T*') { $self->process_t_star($block)}
  elsif($opname eq 'Tm') { $self->process_tm($block)    }
  elsif($opname eq "\'") { $self->process_squote($block)}
  elsif($opname eq '\"') { $self->process_dquote($block)}
  elsif($opname eq 'Tj') { $self->process_tj($block)    }
  elsif($opname eq 'TJ') { $self->process_cap_tj($block)}
  elsif($opname eq 'Tc') { $self->process_tc($block)    }
  elsif($opname eq 'Tw') { $self->process_tw($block)    }
  elsif($opname eq 'Tw') { $self->process_tz($block)    }
  elsif($opname eq 'gs') { $self->noop($block)          }
  elsif($opname eq 'ri') { $self->noop($block)          }
  elsif($opname eq 'i')  { $self->noop($block)          }
  else
  {
    print "Need to deal with $opname\n"; 
  }
}

sub noop
{
  # Do nothing...
}

# Begin polygon at the given coordinates.

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

#  print "Line to (".join(",",@coords).")\n";

  push(@{$self->{poly}}, \@coords);

  if($debug>3)
  {
    print "Added point. New poly: ".poly_to_string($self->{poly})."\n";
    print "Poly is ".@{$self->{poly}}." long\n";
  }
}

sub process_h
{
  my $self = shift;
  my $block = shift;
  $self->do_h;
}

sub do_h
{
  my $self = shift;

  my $first_x = $self->{poly}->[0]->[0];
  my $first_y = $self->{poly}->[0]->[1];
  my $last_x = $self->{poly}->[-1]->[0];
  my $last_y = $self->{poly}->[-1]->[1];

  # No need to close the path if it's already closed.

  if($first_x == $last_x && $first_y == $last_y)
  {
    return;
  }

  my @coords = ($first_x, $first_y);

  push(@{$self->{poly}}, \@coords);
}

sub process_b_star
{
  my $self = shift;
  my $block = shift;

  $self->do_fill('B*');
}

sub process_b
{
  my $self = shift;
  my $block = shift;

  $self->do_fill('B');
}

sub process_cap_f
{
  my $self = shift;
  my $block = shift;

  $self->do_fill('F');
}

sub process_f
{
  my $self = shift;
  my $opname = shift;

  $self->do_fill('f');
}

sub process_f_star
{
  my $self = shift;
  my $opname = shift;

  $self->do_fill('f*');
}

# Handles f, F, B, and B*
# These commands fill and/or stroke a previously-defined drawing path. 
# When this happens we examine the path we've recorded so far to see if it
# looks like a rectangle. If it does, then we add the rectangle to the list
# of rectangles. Either way, we reset things for the next polygon.

sub do_fill
{
  my $self = shift;
  my $opname = shift;

  my $obj = get_rect_from_poly($self->{poly});

  if($obj->{type} eq 'rect')
  {
    $obj->{page} = $self->{page};
    $obj->{mediabox} = $self->{mediabox};


    $obj->{fill_color} = $self->{fill_color};
    $obj->{stroke_color} = $self->{stroke_color};
    $obj->{draw_op} = $opname;

    my $objects_ref = $self->{objects};
    my @objects = @$objects_ref;

    push @objects, $obj;
    $self->{objects} = \@objects;

    if($debug>3)
    {
      print "f: Adding rectangle from poly\n";
    }
  }
  else
  {
    if($debug>3)
    {
      print "fill: Did not add rectangle\n";
    }
  }

  $self->{poly} = [];
}

sub process_w
{
  my $self = shift;

  # No-op since we don't care about line widths.
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

  $self->{poly} = \@poly;
}

# Set the current color space for stroking operations

sub process_cap_cs
{
  my $self = shift;
  my $block = shift;
  my @args = @{$block->{args}};

  if(@args != 1)
  {
    print "Error! cs with ".@args." arguments.\n";
  }

  $self->{stroke_cs} = $args[0]{'value'};
}

# Set the current color space for non-stroking operations

sub process_cs
{
  my $self = shift;
  my $block = shift;
  my @args = @{$block->{args}};

  if(@args != 1)
  {
    print "Error! cs with ".@args." arguments.\n";
  }

  $self->{fill_cs} = $args[0]{'value'};
}

# TODO: Refactor this so there's a separate function for each operation
# that calls the relevant color-based function (g, rbg, etc).

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

sub process_s
{
  my $self = shift;
  my $block = shift;
  $self->do_h;
  $self->do_cap_s;
}

sub process_cap_s
{
  my $self = shift;
  my $block = shift;
  $self->do_cap_s;
}

sub do_cap_s
{
  my $self = shift;

  # A no-op since we don't care about stroking.
}

sub process_n
{
  # n is basically a no-op since we don't care about clipping paths.
}

sub process_cap_w
{
  # W is basically a no-op since we don't care about clipping paths.
}

sub process_w_star
{
  # W* is basically a no-op since we don't care about clipping paths.
}

sub process_cm
{
  my $self = shift;
  my $block = shift;
  my @args = @{$block->{args}};

  if(@args != 6)
  {
    print "Error! cm with ".@args." arguments instead of 6.\n";
    return;
  }

  $self->{ct_matrix} = pdf_matrix->new(
      $args[0]->{value},
      $args[1]->{value},
      $args[2]->{value},
      $args[3]->{value},
      $args[4]->{value},
      $args[5]->{value});
}

sub process_tl
{
  my $self = shift;
  my $block = shift;

  my @args = @{$block->{args}};

  if(@args != 1)
  {
    print "Error! TL with ".@args." arguments instead of 1.\n";
    return;
  }

  $self->{leading} = $args[0]->{value};
}

sub process_tz
{
  my $self = shift;
  my $block = shift;

  my @args = @{$block->{args}};

  if(@args != 1)
  {
    print "Error! Tz with ".@args." arguments instead of 1.\n";
    return;
  }

  $self->{hscale} = $args[0]->{value}/100;
}

sub process_tc
{
  my $self = shift;
  my $block = shift;

  my @args = @{$block->{args}};

  if(@args != 1)
  {
    print "Error! Tc with ".@args." arguments instead of 1.\n";
    return;
  }

  $self->{char_spacing} = $args[0]->{value};
}

sub process_tw
{
  my $self = shift;
  my $block = shift;

  my @args = @{$block->{args}};

  if(@args != 1)
  {
    print "Error! Tw with ".@args." arguments instead of 1.\n";
    return;
  }

  $self->{word_spacing} = $args[0]->{value};
}

sub process_tf
{
  my $self = shift;

  my $block = shift;

  my @args = @{$block->{args}};

  if(@args == 2 && $args[1]->{type} eq 'number')
  {
    $self->{font_size} = $args[1]->{value};
  }
  else
  {
    my $n = @args;
    my $type = $args[1]->{type};

    print "Error! n is $n, type is $type\n";
  }
}

# Move to the start of the next line, setting the leading as a side-effect

sub process_cap_td
{
  my $self = shift;
  my $block = shift;

  my @args = @{$block->{args}};

  if(@args != 2)
  {
    print "Error! TD with ".@args." arguments instead of 2.\n";
    return;
  }

  $self->do_td($args[0]->{value}, $args[1]->{value});

  $self->{leading} = 0-($args[1]->{value});
}

# Move to the start of the next line.

sub process_td
{
  my $self = shift;
  my $block = shift;

  my @args = @{$block->{args}};

  if(@args != 2)
  {
    print "Error! Td with ".@args." arguments instead of 2.\n";
    return;
  }

  $self->do_td($args[0]->{value}, $args[1]->{value});
}

# Process already-accumulated text and then move the text pointer to a new
# location.

sub do_td
{
  my $self = shift;
  my $tx = shift;
  my $ty = shift;

  # Process the text we've already got and put it in a new text object.

  $self->{line_matrix}->translate($tx, $ty);
  $self->{text_matrix} = $self->{line_matrix}->copy;
}

sub move_text_matrix
{
  my $self = shift;
  my $tx = shift;
  my $ty = shift;

  $self->{text_matrix}->translate($tx, $ty);
}

# Move the pen leading text units to start a new line.

sub process_t_star
{
  my $self = shift;
  my $block = shift;
  my @args = @{$block->{args}};

  if(@args != 0)
  {
    print "Error! T* with ".@args." arguments instead of 0.\n";
    return;
  }

  $self->do_td(0, $self->{leading});
}

# Take the accumulated text from prior
# text operations and turn it into a completed text object, then reset
# things for the next batch of text-drawing commands.

sub process_text
{
  my $self = shift;
  my $text = shift;
  my $hoffset = shift;

  my $text_width = $self->get_text_width($text,$hoffset)
                    * $self->{text_matrix}->get_xscale
                    * $self->{ct_matrix}->get_xscale;
  my $text_height = $self->{font_size} 
                    * $self->{text_matrix}->get_yscale
                    * $self->{ct_matrix}->get_yscale;
                  
  my $tx = $self->{text_matrix}->get_tx + $self->{ct_matrix}->get_tx;
  my $ty = $self->{text_matrix}->get_ty + $self->{ct_matrix}->get_ty;

  # I'm not sure what to do with diagonal text, but it's not very likely
  # to be redacted, so ignoring it seems fine for the first version.
  # TODO: Deal with diagonal text more intelligently.
  if($self->{text_matrix}->is_horizontal)
  {
    my $obj = pdf_object->text(
        $self->{page},
        $text, 
        $self->{font_size},
        $tx,
        $ty,
        $text_width,
        $text_height);

    if(!$obj->has_type('text'))
    {
      print "Error in text object creation!";
    }
    else
    {
      my $objects_ref = $self->{objects};
      my @objects = @$objects_ref;
      push @objects, $obj;
      $self->{objects} = \@objects;
    }
  }

  $self->{text_matrix}->translate($text_width,0);
}

# Set the text matrix. This is complicated and probably needs a better comment.

sub process_tm
{
  my $self = shift;
  my $block = shift;
  my @args = @{$block->{args}};

  if(@args != 6)
  {
    print "Error! Tm with ".@args." arguments instead of 6.\n";
    return;
  }

  $self->{text_matrix} = pdf_matrix->new(
      $args[0]->{value},
      $args[1]->{value},
      $args[2]->{value},
      $args[3]->{value},
      $args[4]->{value},
      $args[5]->{value});

  $self->{line_matrix} = $self->{text_matrix}->copy;
}

# The single-quote operator is equivalent to a T* followed by a Tj.
# As such we mimick that series of steps here.

sub process_squote
{
  my $self = shift;
  my $block = shift;
  my @args = @{$block->{args}};

  if(@args!=1)
  {
    print "Error! Single-quote operator with arguments.\n";
    return;
  }

  $self->do_squote($args[0]->{'value'});
}

# Do a Td operation and then remember the first argument as the current text.

sub do_squote
{
  my $self = shift;
  my $string = shift;

  # The T* operator is just a Td operator with the current leading as the
  # ty value.
  $self->do_td(0, $self->{leading});

  $self->{text} = $string;
}

# The double-quote operator does some stuff we don't care about and then
# invokes the single-quote operator.

sub process_dquote
{
  my $self = shift;
  my $block = shift;
  my @args = @{$block->{args}};

  if(@args!=3)
  {
    print "Error! Single-quote operator with arguments.\n";
    return;
  }

  $self->{word_spacing} = $args[0]->{value};
  $self->{char_spacing} = $args[1]->{value};

  $self->do_squote($args[2]->{'value'});
}

# Add a string to the current text.

sub process_tj
{
  my $self = shift;
  my $block = shift;
  my @args = @{$block->{args}};

  if (@args != 1)
  {
    print "Error! Found tj with ".@args." arguments instead of 1.\n";
    return;
  }

  if(  $args[0]->{type} ne 'string'
    && $args[0]->{type} ne 'hexstring')
  {
    print "Error! Found Tj with type of ".$args[0]->{type}."\n";
    return;
  }

  $self->process_text($args[0]->{value}, 0);
}

# The "real" PDF spec creates a new text object for every text-drawing
# operation, but we'd like to deal with fewer text objects and our layout
# algorithm isn't that precise anyway. So we just maintain a variable
# called hoffset that tells us how wide the text string is so far.
# Here we update it based on new text.

sub get_text_width
{
  my $self = shift;
  my $text = shift;
  my $hoffset = shift;

  my $width = get_width_for_string($text);

  my $char_spacing = $self->{char_spacing} * length($text);
 
  my $space_count = ($text =~ tr/ //); # Note: this destroys $text

  my $word_spacing = $self->{word_spacing} * $space_count;

  return (($width-$hoffset/1000)*$self->{font_size}
                 +$char_spacing
                 +$word_spacing)
             * $self->{hscale};
}

# In an ideal world we'd take the font as an additional argument and look up
# the actual widths for each character in that font. But for now we're going
# to approximate it by saying that the average character in the average
# font is half as wide as it is tall.

sub get_width_for_string
{
  my $text = shift;

  return 0.5 * length($text);
}


# Add some strings to the current text, with flexible placing.

sub process_cap_tj
{
  my $self = shift;
  my $block = shift;
  my @args = @{$block->{args}};

  if (@args != 1)
  {
    print "Error! TJ with ".@args." arguments instead of 1.\n";
    return;
  }

  if($args[0]->{type} ne 'array')
  {
    print "Error! TJ with argument type ".$args[0]->{type}."\n";
    return;
  }

  my $text = '';
  my $hoffset = 0;

  my @strings = @{$args[0]->{value}};

  foreach my $element (@strings)
  {
    if ($element->{type} eq 'string' || $element->{type} eq 'hexstring')
    {
      $text .= $element->{'value'};
    }
    elsif ($element->{type} eq 'number')
    {
      $hoffset += $element->{'value'};
    }
    else
    {
      print "Error! Unrecognized TJ arguments\n";
    }
  }

  $self->process_text($text, $hoffset);
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

#  my $dumper = new Dumpvalue;
#  $dumper->dumpValue($poly_ref);

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

  return pdf_object->rect($x, $y, $width, $height);
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

  my $rects_ref = $self->get_objects_with_type('rect');

  return $rects_ref;
}

sub get_texts
{
  my $self = shift;
  my $texts_ref = $self->get_objects_with_type('text');

#  my $dumper = new Dumpvalue;
#  $dumper->dumpValue($texts_ref);

  return $texts_ref;
}

return 1;

