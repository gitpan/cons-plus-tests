#! /usr/bin/env perl
#
#	Install a file from a subdirectory two levels deep
#	into a top-level directory referenced by "../..".
#	Make sure it doesn't get installed if the target is ".",
#	but does if the target is "../.." or "/".
#

# $Id: t0056.t,v 1.4 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => '../.. above top-level directory');

$test->subdir('sub', ['sub', 'dir']);

#
$workpath_install_foo_pl = $test->workpath('install', 'foo.pl');
$sub_dir = $test->catfile('sub', 'dir');
$updir_updir = $test->catfile($test->updir, $test->updir);
$updir_updir_install = $test->catfile($updir_updir, 'install');

#
$test->write([$sub_dir, 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Install \$env '$updir_updir_install', 'foo.pl';
_EOF_

$test->write([$sub_dir, 'foo.pl'], <<_EOF_);
$Config{startperl}
print "Called with arg 0 = '\$0'\n";
_EOF_

$test->run('chdir' => $sub_dir, targets => ".");
$test->must_not_exist($workpath_install_foo_pl);

$test->run('chdir' => $sub_dir, targets => $updir_updir);

$test->execute(prog => $workpath_install_foo_pl, interpreter => $^X, stdout => <<_EOF_);
Called with arg 0 = '\Q$workpath_install_foo_pl\E'
_EOF_

$test->run('chdir' => $sub_dir, flags => '-r', targets => $updir_updir);
$test->must_not_exist($workpath_install_foo_pl);

$test->run('chdir' => $sub_dir, targets => '/');

$test->execute(prog => $workpath_install_foo_pl, interpreter => $^X, stdout => <<_EOF_);
Called with arg 0 = '\Q$workpath_install_foo_pl\E'
_EOF_

#
$test->pass;
__END__
