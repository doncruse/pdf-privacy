use lib './lib';

use Mydump;

sub get_text_rects
{
  my $tree = shift;
  my $pagenum = shift;

  return () if(!defined($tree));

  Mydump->init($pagenum);

  $tree->render("Mydump");

  my @list = Mydump->getList;

  return Mydump->getList;
}

1;

