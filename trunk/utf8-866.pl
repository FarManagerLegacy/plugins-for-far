#!perl -w

use Encode qw(encode decode);

my $content = '';
open my $fh, '<', $ARGV[0] or die $!;
{
  local $/;
  $content = <$fh>;
}
close $fh;

if ($content =~ s/^\xEF\xBB\xBF//) {
  print encode("cp866", decode("utf8", $content));
}
else {
  print $content;
}
