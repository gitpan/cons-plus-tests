#! /usr/bin/env perl
#
#	Create a work subdirectory and a repository subdirectory.
#	The repository contains one .c file, which includes a .h
#	file, which in turn includes another .h file.  The work
#	subdirectory contains a Construct file with Repository
#	pointing to the repository and 'Program' to build an
#	executable from the .c file.  Invoke cons in the work
#	subdirectory to build the executable from the repository
#	source files.  Check that the executable was built correctly.
#	Create a work copy of the "intermediate" .h file.  Build
#	again.  Check that the executable picked up the work .h
#	file.  Create a work copy of the .c file.  Build again and
#	check the executable.  Create a work copy of the last .h
#	file.  Build and check...  Remove the work copies of the
#	.c file and the intermediate .h file.  Build and check...
#	Remove the work copy of the last .h file.  Build and check
#	that we're back to the repository copies of all files.
#

# $Id: t0111.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

use Test::Cmd::Cons qw($_exe);

$test = Test::Cmd::Cons->new('string' => 'Repository nested .h files');

$test->subdir('repository', 'work');

#
$foo_exe = "foo$_exe";
$workpath_repository =  $test->workpath('repository');
$work_foo =  $test->catfile('work', 'foo');
$work_foo_h =  $test->catfile('work', 'foo.h');
$work_bar_h =  $test->catfile('work', 'bar.h');
$work_main_c =  $test->catfile('work', 'main.c');

#
$test->write(['work', 'Construct'], <<_EOF_);
\%env_hash = ( ${\$test->cons_env} );
\$env_hash{CPPPATH} = '.';
\$env = new cons ( \%env_hash );
Repository '$workpath_repository';
Program \$env '$foo_exe', 'main.c';
_EOF_

$test->write(['repository', 'foo.h'], <<'_EOF_');
#define	STRING1	"repository/foo.h"
#include <bar.h>
_EOF_

$test->write(['repository', 'bar.h'], <<'_EOF_');
#define	STRING2	"repository/bar.h"
_EOF_

$test->write(['repository', 'main.c'], <<'_EOF_');
#include <foo.h>
main()
{
	printf("%s\n", STRING1);
	printf("%s\n", STRING2);
	printf("repository/main.c\n");
	exit (0);
}
_EOF_


# Make the repository non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository', 0);

$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository/foo.h
repository/bar.h
repository/main.c
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

$test->write(['work', 'foo.h'], <<'_EOF_');
#define	STRING1	"work/foo.h"
#include <bar.h>
_EOF_

$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
work/foo.h
repository/bar.h
repository/main.c
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

$test->write(['work', 'main.c'], <<'_EOF_');
#include <foo.h>
main()
{
	printf("%s\n", STRING1);
	printf("%s\n", STRING2);
	printf("work/main.c\n");
	exit (0);
}
_EOF_

$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
work/foo.h
repository/bar.h
work/main.c
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

$test->write(['work', 'bar.h'], <<'_EOF_');
#define	STRING2	"work/bar.h"
_EOF_

$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
work/foo.h
work/bar.h
work/main.c
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

$test->unlink($work_main_c);

$test->unlink($work_foo_h);

$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository/foo.h
work/bar.h
repository/main.c
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

$test->unlink($work_bar_h);

$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository/foo.h
repository/bar.h
repository/main.c
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

#
$test->pass;
__END__
