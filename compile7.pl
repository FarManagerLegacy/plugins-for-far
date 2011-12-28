#!perl -w

use strict;
use Win32API::Registry 0.21 qw(:ALL);
use Cwd qw(fast_abs_path);
use File::Path qw(make_path);
use ActiveState::DateTime qw(gmt_offset);
use Options;

my $options = new Options(
  params => [['api', 'a', undef, 'Far Plugins API version (1, 2, 3)']],
  flags => [['lite', 'l', 'Use Delphi 7 Lite compiler'], ['help', 'h', 'Display this usage guide']] );

$options->get_options();
if ($options->get_result('help')) {
    $options->print_usage();
    exit(1);
}

my ($dcc, $root, $lib, $brc, $sysdcu7);
(my $appname = fast_abs_path('.')) =~ s|^.*[\\/]||;

if ($options->get_result('lite')) {  
  # Расположение Delphi7
  $0 = $^X unless ($^X =~ m%(^|[/\\])perl(\.exe)?$%i);
  $root = $0;
  $root =~ s/\\[^\\]+$/\\NoBackup\\Delphi7/;
  $dcc = "$root\\dcc32.exe";
  $brc = "$root\\brc32.exe";

  # Библиотеки Delphi7
  $lib = '';
  $sysdcu7 = "$root\\SysDcu7";
}
else {
  # Расположение Delphi7
  my ($key, $type);
  RegOpenKeyEx(HKEY_LOCAL_MACHINE, 'Software\Borland\Delphi\7.0', 0, KEY_READ, $key);
  RegQueryValueEx($key, "App", [], $type, $dcc, []);
  $dcc =~ s/\\[^\\]+$/\\dcc32.exe/;
  $brc = $dcc;
  $brc =~ s/\\[^\\]+$/\\brc32.exe/;
  RegQueryValueEx($key, "RootDir", [], $type, $root, []);
  $root =~ s/\\$//;
  RegCloseKey($key);

  # Библиотеки Delphi7
  RegOpenKeyEx(HKEY_CURRENT_USER, 'Software\Borland\Delphi\7.0\Library', 0, KEY_READ, $key);
  RegQueryValueEx($key, "Search Path", [], $type, $lib, []);
  RegCloseKey($key);

  $lib =~ s/\$\(DELPHI\)/$root/gi;
  $lib =~ s/\\$//;
  $lib = '';
  $sysdcu7 = "$root\\AddLib\\SysDcu7";
}

print "Dcc: $dcc\n";

my $api = $options->get_result('api') - 1;

my @UStr = ('Far1', 'Far2', 'Far3');
my @UStrAdd = (';ANSI', ';UNICODE;UNICODE_CTRLS', ';UNICODE;UNICODE_CTRLS');
open CFG, '+<', "$appname.cfg";
undef $/;
my $cfg = <CFG>;
while ($cfg =~ s/^(-D.*)UNICODE[^;]*;?/$1/mi) {};
while ($cfg =~ s/^(-D.*)Far[1-3];?/$1/mi) {};
# $cfg =~ s/^(-[UOIR].*)(FarAPI[^;]*)/$1FarAPI\\$UStr[$api]/mig;
$cfg =~ s/^-E.*$/-E"..\\Bin\\$UStr[$api]\\$appname"/mi;
$cfg =~ s/^-N.*$/-N"..\\Dcu\\$UStr[$api]\\$appname"/mi;
seek CFG, 0, 0;
print CFG $cfg;
truncate CFG, tell(CFG);
close CFG;

make_path "..\\Bin\\$UStr[$api]\\$appname", "..\\Dcu\\$UStr[$api]\\$appname";

my %subst = ( Version => '', FarVersion => '', CompileDate => '');
open(VERSION, '<', 'version.txt') and $subst{Version} = <VERSION>, close VERSION;
$subst{FarVersion} = ('1.7x', '2', '3')[$api];
$subst{CompileDate} = (sprintf '%02d.%02d.%04d', sub{($_[3], $_[4] + 1, $_[5] + 1900)}->(localtime));

open DATETIME, '>', 'datetime.inc';
print DATETIME "const\n";
print DATETIME '  CompileTime = ', 25569 + (time + gmt_offset() / 100 * 60 * 60 ) / (60 * 60 * 24), ";\n";
print DATETIME '  CompileDateStr = \'', $subst{CompileDate}, "';\n";
print DATETIME '  CompileTimeStr = \'', (sprintf '%02d:%02d:%02d', (localtime)[2, 1, 0]), "';\n";
close DATETIME;

if ($subst{Version} and open(VERSION, '+<', 'versioninfo.rc')) {
  my @Version = split /\./, $subst{Version};
  @Version = (@Version, (0) x (3 - $#Version));
  undef $/;
  my $data = <VERSION>;
  my $ver = join ',', @Version;
  $data =~ s/((?:FILEVERSION|PRODUCTVERSION)\s+)(?:\d+,\s*)+\d+/$1.$ver/eg;
  $ver = join '.', @Version;
  $data =~ s/("(?:FileVersion|ProductVersion)",\s+")(?:\d+\.)+\d+/$1.$ver/eg;
  seek VERSION, 0, 0;
  print VERSION $data;
  truncate VERSION, tell(VERSION);
  close VERSION;
}

system "$brc -r $_" while(<*.rc>);
print <<DCC if 0;
  $dcc $appname.dpr -B -Q
  -I\"$lib;..\\Dcu\\$UStr[$api]\\$appname\"
  -U\"$sysdcu7;$lib;..\\Dcu\\$UStr[$api]\\$appname\"
  -LE\"$lib\" -R\"$lib\"
  -DRelease;NOT_USE_RICHEDIT;$UStr[$api]$UStrAdd[$api]
DCC
exit 1 if system "$dcc $appname.dpr -B -Q " .
  "-I\"$lib;..\\Dcu\\$UStr[$api]\\$appname\" " .
  "-U\"$sysdcu7;$lib;..\\Dcu\\$UStr[$api]\\$appname\" " .
  "-LE\"$lib\" -R\"$lib\" " .
  "-DRelease;NOT_USE_RICHEDIT;$UStr[$api]$UStrAdd[$api]";

use Encode qw(encode decode);
use File::Copy;

while(glob('Doc\*.*')) {
  my $file = $_;
  $file =~ s/^Doc\\//i;
  $file = "..\\Bin\\$UStr[$api]\\$appname\\$file";
  if (!-f $file || (stat($_))[9] > (stat($file))[9]) {
    if ($file =~ m|^(.*)tpl\.([^/\\].+)$|i) {
      $file = $1 . $2;
      my $content = '';
      open my $fh, '<', $_;
      {
        local $/;
        $content = <$fh>;
      }
      close $fh;
      $content =~ s/\$\{$_\}/$subst{$_}/gei for (keys %subst);

      open $fh, '>', $file;
      if (!$api && $content =~ s/^\xEF\xBB\xBF//) {
        print $fh encode("cp866", decode("utf8", $content));
      }
      elsif ($api && $content !~ m/^\xEF\xBB\xBF/) {
        print $fh "\xEF\xBB\xBF", encode("utf8", decode("cp866", $content));
      }
      else {
        print $fh $content;
      }
      close $fh;
    }
    else {
      copy($_, $file);
    }
  }
}

my $ver = $subst{Version};
$ver =~ s/\.//g;
my @USuf = ('A', 'W', '');
system "rar.exe u -as -mdg -m5 -r0 -ep1 -rr -s ..\\Bin\\$appname$USuf[$api].v$ver.rar ..\\Bin\\$UStr[$api]\\$appname\\*.* >nul";
