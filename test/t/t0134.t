#! /usr/bin/env perl
#
#	Define an executable to be built from a single .c file in
#	the repository subdirectory.  The .c files prints a single
#	string to be supplied via '-DSTRING=' from CFLAGS in the
#	build environment.  Build the executable in the repository;
#	make sure the executable is build with the default STRING
#	value.  Create a work-subdirectory override file that
#	changes CFLAGS when generating the .o file.  Invoke cons
#	in the work subdirectory with the override file;; make sure
#	the executable is built with the overridden STRING value.
#	Invoke cons again in the work subdirectory, without the
#	override; make sure the executable has reverted to the
#	original STRING value.
#

# $Id: t0134.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

use Test::Cmd::Cons qw($_exe $_o);

$test = Test::Cmd::Cons->new('string' => '-o overrides, -R');

$test->subdir('work', 'repository');

#
$foo_exe = "foo$_exe";
$workpath_repository = $test->workpath('repository');
$repository_foo = $test->catfile('repository', 'foo');
$work_foo = $test->catfile('work', 'foo');

$flags = "-R $workpath_repository";

#
$test->write(['repository', 'Construct'], <<_EOF_);
\%env_hash = ( ${\$test->cons_env} );
\$env_hash{CFLAGS} = '%COPT';
\$env_hash{COPT} = '-DSTRING=\\"FOO\\"';
\$env = new cons ( \%env_hash );
Program \$env '$foo_exe', 'foo.c';
_EOF_

$test->write(['repository', 'foo.c'], <<'_EOF_');
main()
{
	printf("repository/foo.c:  %s\n", STRING);
	exit (0);
}
_EOF_

$test->write(['work', 'over'], <<_EOF_);
Override '\Q$_o\E\$', COPT => '-DSTRING=\\"OVERRIDE\\"';
_EOF_


#
$test->run('chdir' => 'repository', targets => ".");

$test->execute(prog => $repository_foo, stdout => <<_EOF_);
repository/foo.c:  FOO
_EOF_

# Make the repository non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository', 0);

$test->run('chdir' => 'work', flags => "$flags -o over", targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository/foo.c:  OVERRIDE
_EOF_

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository/foo.c:  FOO
_EOF_

#
$test->pass;
__END__
