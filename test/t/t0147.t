#! /usr/bin/env perl
#
#	Invoke cons in a work directory to install a file from a
#	repository subdirectory to a differently-named file in an
#	installation subdirectory.  Add a local Construct file to
#	install the repository file to another name in the installation
#	subdirectory.  Add a local work copy of the file and install it
#	to the file named in in the local Construct file.  Remove the
#	local Construct file and install the local work copy of the file
#	to the installation file named in the repository Constrcut file.
#

# $Id: t0147.t,v 1.4 2000/06/01 22:00:50 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => 'InstallAs, -R');

$test->subdir('work', 'repository', 'install');

#
$workpath_repository = $test->workpath('repository');
$workpath_install = $test->workpath('install');
$workpath_install_aaa_pl = $test->workpath('install', 'aaa_pl');
$workpath_install_bbb_pl = $test->workpath('install', 'bbb_pl');
$work_Construct = $test->catfile('work', 'Construct');

$flags = "-R $workpath_repository";

#
$test->write(['repository', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
InstallAs \$env '$workpath_install_aaa_pl', 'foo.pl';
_EOF_

$test->write(['repository', 'foo.pl'], <<_EOF_);
$Config{startperl}
print "repository/foo.pl called with arg 0 = '\$0'\\n";
_EOF_

# Make the repository non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository', 0);

$test->run('chdir' => 'work', flags => $flags, targets => "$workpath_install");

$test->execute(prog => $workpath_install_aaa_pl, interpreter => $^X, stdout => <<_EOF_);
repository/foo.pl called with arg 0 = '\Q$workpath_install_aaa_pl\E'
_EOF_

$test->write(['work', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
InstallAs \$env '$workpath_install_bbb_pl', 'foo.pl';
_EOF_

$test->run('chdir' => 'work', flags => $flags, targets => "$workpath_install");

$test->execute(prog => $workpath_install_bbb_pl, interpreter => $^X, stdout => <<_EOF_);
repository/foo.pl called with arg 0 = '\Q$workpath_install_bbb_pl\E'
_EOF_

$test->write(['work', 'foo.pl'], <<_EOF_);
$Config{startperl}
print "work/foo.pl called with arg 0 = '\$0'\\n";
_EOF_

$test->run('chdir' => 'work', flags => $flags, targets => "$workpath_install");

$test->execute(prog => $workpath_install_bbb_pl, interpreter => $^X, stdout => <<_EOF_);
work/foo.pl called with arg 0 = '\Q$workpath_install_bbb_pl\E'
_EOF_

$test->unlink($work_Construct);

$test->run('chdir' => 'work', flags => $flags, targets => "$workpath_install");

$test->execute(prog => $workpath_install_aaa_pl, interpreter => $^X, stdout => <<_EOF_);
work/foo.pl called with arg 0 = '\Q$workpath_install_aaa_pl\E'
_EOF_

#
$test->pass;
__END__
