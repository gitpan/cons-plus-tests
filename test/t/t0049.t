#! /usr/bin/env perl
#
#	Create a file in a subdirectory.  Check that InstallAs from a
#	file to a list fails as it should.  Check that InstallAs from a
#	list to a file fails as it should.  Check that InstallAs with
#	unequal length lists fails as it should.  Use InstallAs to
#	install file into another subdirectory with a different name;
#	check that it succeeded.  Use InstallAs to install a list of
#	two files (the same file twice) to two differently-named files
#	in another subdirectory; check that it succeeded.
#

# $Id: t0049.t,v 1.2 2000/06/01 22:00:45 knight Exp $

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

use Test::Cmd::Cons;
use Config;

$test = Test::Cmd::Cons->new(string => 'InstallAs');

$test->subdir('src');

#
$src_Conscript = $test->catfile('src', 'Conscript');
$install_a1_pl = $test->catfile('install', 'a1.pl');
$install_a2_pl = $test->catfile('install', 'a2.pl');
$install_a3_pl = $test->catfile('install', 'a3.pl');
$install_a4_pl = $test->catfile('install', 'a4.pl');
$install_b4_pl = $test->catfile('install', 'b4.pl');
$install_a5_pl = $test->catfile('install', 'a5.pl');
$install_a6_pl = $test->catfile('install', 'a6.pl');
$install_b6_pl = $test->catfile('install', 'b6.pl');
$workpath_install_a5_pl = $test->workpath('install', 'a5.pl');
$workpath_install_a6_pl = $test->workpath('install', 'a6.pl');
$workpath_install_b6_pl = $test->workpath('install', 'b6.pl');

#
$test->write('Construct', <<_EOF_);
Build '$src_Conscript';
_EOF_

$test->write(['src', 'a.pl'], <<_EOF_);
$Config{startperl}
print "Called with arg 0 = '\$0'\\n";
_EOF_

#
$test->write($src_Conscript, <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
InstallAs \$env ['#$install_a1_pl'], 'a.pl';
_EOF_

#
$test->run(targets => ".", fail => '$? == 0'); # expect failure
$test->must_not_exist($install_a1_pl);

#
$test->write($src_Conscript, <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
InstallAs \$env '#$install_a2_pl', ['a.pl'];
_EOF_

#
$test->run(targets => ".", fail => '$? == 0'); # expect failure
$test->must_not_exist($install_a2_pl);

#
$test->write($src_Conscript, <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
InstallAs \$env ['#$install_a3_pl'], ['a.pl', 'a.pl'];
_EOF_

#
$test->run(targets => ".", fail => '$? == 0'); # expect failure
$test->must_not_exist($install_a3_pl);

#
$test->write($src_Conscript, <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
InstallAs \$env ['#$install_a4_pl', '$install_b4_pl'], ['a.pl'];
_EOF_

#
$test->run(targets => ".", fail => '$? == 0'); # expect failure
$test->must_not_exist($install_a4_pl);
$test->must_not_exist($install_b4_pl);

#
$test->write($src_Conscript, <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
InstallAs \$env '#$install_a5_pl', 'a.pl';
_EOF_

#
$test->run(targets => ".");

$test->execute(prog => $workpath_install_a5_pl, interpreter => $^X, stdout => <<_EOF_);
Called with arg 0 = '\Q$workpath_install_a5_pl\E'
_EOF_

#
$test->write($src_Conscript, <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
InstallAs \$env ['#$install_a6_pl', '#$install_b6_pl'], ['a.pl', 'a.pl'];
_EOF_

#
$test->run(targets => ".");
$test->execute(prog => $workpath_install_a6_pl, interpreter => $^X, stdout => <<_EOF_);
Called with arg 0 = '\Q$workpath_install_a6_pl\E'
_EOF_
$test->execute(prog => $workpath_install_b6_pl, interpreter => $^X, stdout => <<_EOF_);
Called with arg 0 = '\Q$workpath_install_b6_pl\E'
_EOF_

#
$test->pass;
__END__
