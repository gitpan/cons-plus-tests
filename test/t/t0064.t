#! /usr/bin/env perl
#
#	Arrange for two files to be Installed in two different
#	subdirectories of an installation directory.  Put a copy of
#	the first file by hand in the first subdirectory.  Remove write
#	permission from the first subdirectory and its file.   Invoke
#	Cons -k.  Check standard output and error output to make sure
#	the install on the non-writable directory failed.  Check that
#	the second file was properly installed in the second subdirectory.
#

# $Id: t0064.t,v 1.4 2000/06/19 22:07:36 knight Exp $

# Copyright (c) 1996-2000 Free Software Foundation, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.

use Test::Cmd::Cons qw($_is_win32);
use Config;

$test = Test::Cmd::Cons->new(string => 'Install failure');

$test->subdir('src', 'install', ['install', 'subdir1'], ['install', 'subdir2']);

#
$install_subdir1 = $test->catfile('install', 'subdir1');
$install_subdir1_foo1_pl = $test->catfile('install', 'subdir1', 'foo1.pl');
$install_subdir2 = $test->catfile('install', 'subdir2');
$install_subdir2_foo2_pl = $test->catfile('install', 'subdir2', 'foo2.pl');
$workpath_install_subdir2_foo2_pl = $test->workpath($install_subdir2_foo2_pl);
$src_Conscript = $test->catfile('src', 'Conscript');
$src_foo1_pl = $test->catfile('src', 'foo1.pl');
$src_foo2_pl = $test->catfile('src', 'foo2.pl');

#
$test->write('Construct', <<_EOF_);
Build '$src_Conscript';
_EOF_

$test->write($src_Conscript, <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Install \$env '#$install_subdir1', 'foo1.pl';
Install \$env '#$install_subdir2', 'foo2.pl';
_EOF_

$test->write(['src', 'foo1.pl'], <<_EOF_);
$Config{startperl}
print "src/foo1.pl called with arg 0 = '\$0'\n";
_EOF_

$test->write(['src', 'foo2.pl'], <<_EOF_);
$Config{startperl}
print "src/foo2.pl called with arg 0 = '\$0'\n";
_EOF_

$test->write(['install', 'subdir1', 'foo1.pl'], <<_EOF_);
$Config{startperl}
print "install/subdir1/foo1.pl called with arg 0 = '\$0'\n";
_EOF_

# Make sure we can not write to the install file.
# For UNIX systems, we remove write protection.
# For NT systems, we open the file to put a lock on it.
$test->writable($install_subdir1, 0);
my $ret = open(INSTALLED, $install_subdir1_foo1_pl);
$test->no_result(! $ret);

if ($_is_win32) {
    $fail = '$? != 0';
    $stderr = <<_EOF_;
\Q${\$test->basename}: can't install "$src_foo1_pl" to "$install_subdir1_foo1_pl" (Permission denied)\E
_EOF_
} else {
    $fail = '$? == 0';
    # Prior to 5.6.0, the message was "END failed--cleanup aborted."
    # 5.6.0 changed it to "END failed--call queue aborted."
    # Use an expression to match either.
    $stderr = <<_EOF_;
\Q${\$test->basename}: can't install "$src_foo1_pl" to "$install_subdir1_foo1_pl" (Permission denied)\E
\Q${\$test->basename}\E: can't create install.*subdir1.*\.consign\..* \Q(Permission denied)\E
END failed--[\\s\\w]+ aborted.
_EOF_
}

$test->run(flags => '-k', targets => ".", fail => $fail, stdout => <<_EOF_, stderr => $stderr);
\QInstall $src_foo1_pl as $install_subdir1_foo1_pl\E
\QInstall $src_foo2_pl as $install_subdir2_foo2_pl\E
_EOF_

$test->execute(prog => $install_subdir2_foo2_pl, interpreter => $^X, stdout => <<_EOF_);
\Qsrc/foo2.pl called with arg 0 = '$workpath_install_subdir2_foo2_pl'\E
_EOF_

close(INSTALLED);

#
$test->pass;
__END__
