use lib './lib';

use render_callback;

sub get_text_rects
{
  my $tree = shift;
  my $pagenum = shift;

  return () if(!defined($tree));

  render_callback->init($pagenum);

  $tree->render("render_callback");

  my @list = render_callback->getList;

  return render_callback->getList;
}

1;

