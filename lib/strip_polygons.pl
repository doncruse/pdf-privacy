use Dumpvalue;

sub strip_polygons
{
  my $pagetree = shift;

  #my $dumper = new Dumpvalue;
  #$dumper->dumpValue($pagetree);

  my @stack = ([@{$pagetree->{blocks}}]);

  # The stack is a list of blocks.  We do depth-first on blocks, but
  # we must be sure to traverse the children of the blocks in their
  # original order.

  my $level = 0;

  while (@stack > 0)
  {
    # keep grabbing the same node until it's empty
    my $node = $stack[-1];

    if (ref $node)
    {
      if (@{$node} > 0)   # Still has children?
      {
        my $block = shift @{$node};   # grab the next child

        if ($block->{type} eq 'block')
        {
          if ($block->{name} eq 'BT')
          {
            # Insert a flag on the stack to say when we leave the BT block
            push @stack, 'BT';
          }
          push @stack, [@{$block->{value}}];  # descend
        }
        else
        {
          if ($block->{type} ne 'op')
          {
            die 'misconception';
          }

          $block = strip_poly_from_block($block);
        }
      }
      else
      {
        # Node is now empty, clear it from the stack
        pop @stack;
      }
    }
    else
    {
      # This is the 'BT' flag we pushed on the stack above
      pop @stack;
    }
  }

  return $pagetree;
}

sub strip_poly_from_block
{
  $block = shift;

  if($block->{name} eq 'Do')
  {
    #$block->{name} = 'h';
    # Do something???
    #my $dumper = new Dumpvalue;
    #$dumper->dumpValue($block);
  }

  if($block->{name} eq 'B' ||
     $block->{name} eq 'B*' ||
     $block->{name} eq 'f' ||
     $block->{name} eq 'F' ||
     $block->{name} eq 'f*')
  {
    $block->{name} = 'S';
  }

  if($block->{name} eq 'b' ||
     $block->{name} eq 'b*')
  {
    $block->{name} = 's';
  }

  print $block->{name}."\n";

  #my $dumper = new Dumpvalue;
  #$dumper->dumpValue($block);

  return $block;
}

1;

