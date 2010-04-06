#!perl -w

use strict;
use Win32API::Registry 0.21 qw(:ALL);
use Cwd qw(fast_abs_path);
use File::Path qw(make_path);

my ($key, $type, $dcc, $root, $lib);
(my $appname = fast_abs_path('.')) =~ s|^.*[\\/]||;

# Расположение Delphi7
RegOpenKeyEx(HKEY_LOCAL_MACHINE, 'Software\Borland\Delphi\7.0', 0, KEY_READ, $key);
RegQueryValueEx($key, "App", [], $type, $dcc, []);
$dcc =~ s/\\[^\\]+$/\\dcc32.exe/;
RegQueryValueEx($key, "RootDir", [], $type, $root, []);
$root =~ s/\\$//;
RegCloseKey($key);

# Библиотеки Delphi7
RegOpenKeyEx(HKEY_CURRENT_USER, 'Software\Borland\Delphi\7.0\Library', 0, KEY_READ, $key);
RegQueryValueEx($key, "Search Path", [], $type, $lib, []);
RegCloseKey($key);

$lib =~ s/\$\(DELPHI\)/$root/gi;
$lib =~ s/\\$//;

my $Unicode = 0 | ($#ARGV != -1);

my @UStr = ('ANSI', 'UNICODE');
my @UStrAdd = ('', ';UNICODE_CTRLS');
open CFG, "+<$appname.cfg";
undef $/;
my $cfg = <CFG>;
$cfg =~ s/^(-D.*)UNICODE;?/$1/mi;
$cfg =~ s/^-E.*$/-E"..\\Bin\\$UStr[$Unicode]\\$appname"/mi;
$cfg =~ s/^-N.*$/-N"..\\Dcu\\$UStr[$Unicode]\\$appname"/mi;
seek CFG, 0, 0;
print CFG $cfg;
truncate CFG, tell(CFG);
close CFG;

make_path "..\\Bin\\$UStr[$Unicode]\\$appname", "..\\Dcu\\$UStr[$Unicode]\\$appname";

#print "$dcc $appname.dpr -B -Q -I\"$lib;..\\Dcu\\$UStr[$Unicode]\\$appname\" -U\"$lib;..\\Dcu\\$UStr[$Unicode]\\$appname\" -LE\"$lib\" -R\"$lib\" -DRelease -D$UStr[$Unicode]\n";
exit 1 if system "$dcc $appname.dpr -B -Q " .
  "-I\"$lib;..\\Dcu\\$UStr[$Unicode]\\$appname\" " .
  "-U\"$root\\AddLib\\SysDcu7;$lib;..\\Dcu\\$UStr[$Unicode]\\$appname\" " .
  "-LE\"$lib\" -R\"$lib\" " .
  "-DRelease;NOT_USE_RICHEDIT;$UStr[$Unicode]$UStrAdd[$Unicode]";