#!perl -w

use strict;
use Cwd qw(fast_abs_path);
use File::Path qw(make_path);

my ($dcc, $root, $lib, $brc);
(my $appname = fast_abs_path('.')) =~ s|^.*[\\/]||;

# Расположение Delphi7
$0 = $^X unless ($^X =~ m%(^|[/\\])perl(\.exe)?$%i);
$root = $0;
$root =~ s/\\[^\\]+$/\\NoBackup\\Delphi7/;
$dcc = "$root\\dcc32.exe";
$brc = "$root\\brc32.exe";

# Библиотеки Delphi7
$lib = '';

my $Unicode = 0 | ($#ARGV != -1);

my @UStr = ('ANSI', 'UNICODE');
my @UStrAdd = ('', ';UNICODE_CTRLS');
open CFG, '+<', "$appname.cfg";
undef $/;
my $cfg = <CFG>;
$cfg =~ s/^(-D.*)UNICODE(?!\w);?/$1/mi;
$cfg =~ s/^-E.*$/-E"..\\Bin\\$UStr[$Unicode]\\$appname"/mi;
$cfg =~ s/^-N.*$/-N"..\\Dcu\\$UStr[$Unicode]\\$appname"/mi;
seek CFG, 0, 0;
print CFG $cfg;
truncate CFG, tell(CFG);
close CFG;

make_path "..\\Bin\\$UStr[$Unicode]\\$appname", "..\\Dcu\\$UStr[$Unicode]\\$appname";

my %subst = ( Version => '', FarVersion => '' );
open(VERSION, '<', 'version.txt') and $subst{Version} = <VERSION>, close VERSION;
$subst{FarVersion} = ('1.7x', '2')[$Unicode];

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
#print <<DCC;
#  $dcc $appname.dpr -B -Q
#  -I\"$lib;..\\Dcu\\$UStr[$Unicode]\\$appname\"
#  -U\"$root\\AddLib\\SysDcu7;$lib;..\\Dcu\\$UStr[$Unicode]\\$appname\"
#  -LE\"$lib\" -R\"$lib\"
#  -DRelease;NOT_USE_RICHEDIT;$UStr[$Unicode]$UStrAdd[$Unicode]
#DCC
exit 1 if system "$dcc $appname.dpr -B -Q " .
  "-I\"$lib;..\\Dcu\\$UStr[$Unicode]\\$appname\" " .
  "-U\"$root\\SysDcu7;$lib;..\\Dcu\\$UStr[$Unicode]\\$appname\" " .
  "-LE\"$lib\" -R\"$lib\" " .
  "-DRelease;NOT_USE_RICHEDIT;$UStr[$Unicode]$UStrAdd[$Unicode]";

use Encode qw(encode decode);
use File::Copy;

while(glob('Doc\*.*')) {
  my $file = $_;
  $file =~ s/^Doc\\//i;
  $file = "..\\Bin\\$UStr[$Unicode]\\$appname\\$file";
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
      if (!$Unicode && $content =~ s/^\xEF\xBB\xBF//) {
        print $fh encode("cp866", decode("utf8", $content));
      }
      elsif ($Unicode && $content !~ m/^\xEF\xBB\xBF/) {
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
my @USuf = ('A', 'W');
system "rar.exe u -as -mdg -m5 -r0 -ep1 -rr -s ..\\Bin\\$appname$USuf[$Unicode].v$ver.rar ..\\Bin\\$UStr[$Unicode]\\$appname\\*.* >nul";
