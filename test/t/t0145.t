#! /usr/bin/env perl
#
#	Make an installation subdirectory in a repository and a
#	work subdirectory.  The repository Construct file specifies
#	installation of a shell script into the install subdirectory.
#	Build in the repository.  Build in the work subdirectory;
#	everything should be up-to-date.  Create a work copy of
#	the Construct file that specifies that the installed file
#	should be Local; build; see that the script was correctly
#	installed in the work/install subdirectory from the repository
#	copy.  Create a work copy of the script; build; see that
#	the work copy was installed.
#

# $Id: t0145.t,v 1.4 2000/06/01 22:00:50 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => 'Install + Local');

$test->subdir('work',
		['work', 'install'],
		'repository',
		['repository', 'install']);

#
$workpath_repository = $test->workpath('repository');
$workpath_repository_foo_pl = $test->workpath('repository', 'foo.pl');
$workpath_work_install_foo_pl = $test->workpath('work', 'install', 'foo.pl');

$flags = "-R $workpath_repository";

#
$test->write(['repository', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Install \$env 'install', 'foo.pl';
_EOF_

$test->write(['repository', 'foo.pl'], <<_EOF_);
$Config{startperl}
print "repository/foo.pl called with arg 0 = '\$0'\\n";
_EOF_

#
$test->run('chdir' => 'repository', targets => ".");

$test->execute(prog => $workpath_repository_foo_pl, interpreter => $^X, stdout => <<_EOF_);
repository/foo.pl called with arg 0 = '\Q$workpath_repository_foo_pl\E'
_EOF_

# Make the repository non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository', 0);

$test->up_to_date('chdir' => 'work', flags => $flags, targets => ".");
$test->must_not_exist($workpath_work_install_foo_pl);

$test->write(['work', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Install \$env 'install', 'foo.pl';
Local qw(install/foo.pl);
_EOF_

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $workpath_work_install_foo_pl, interpreter => $^X, stdout => <<_EOF_);
repository/foo.pl called with arg 0 = '\Q$workpath_work_install_foo_pl\E'
_EOF_

$test->write(['work', 'foo.pl'], <<_EOF_);
$Config{startperl}
print "work/foo.pl called with arg 0 = '\$0'\\n";
_EOF_

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $workpath_work_install_foo_pl, interpreter => $^X, stdout => <<_EOF_);
work/foo.pl called with arg 0 = '\Q$workpath_work_install_foo_pl\E'
_EOF_

#
$test->pass;
__END__
