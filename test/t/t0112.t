#! /usr/bin/env perl
#
#	Create src and include subdirectories in a work subdirectory
#	and a repository subdirectory.  CPPPATH in the repository
#	Construct file specifies src:include.  A .c file in the
#	src subdirectory #includes a .h file in the src subdirectory,
#	which nested #includes a .h file in the include subdirectory.
#	Build in the repository.  Build in the work directory;
#	everything should still be up-to-date.  Create a work copy
#	of the include subdirectory .h file; build.  Create a work
#	copy of the src subdirectory .h file; build.  Remove the
#	work copy of the include subdirectory .h file; build.
#

# $Id: t0112.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => '-R, multi-dir .h');

#
$test->subdir('work',
		['work', 'src'],
		['work', 'include'],
		'repository',
		['repository', 'src'],
		['repository', 'include']);

#
$xxx_exe = "xxx$_exe";
$workpath_repository = $test->workpath('repository');
$work_include_my_string_h = $test->catfile('work', 'include', 'my_string.h');
$work_src_xxx = $test->catfile('work', 'src', 'xxx');
$repository_src_xxx = $test->catfile('repository', 'src', 'xxx');

$flags = "-R $workpath_repository";

#
$test->write(['repository', 'Construct'], <<_EOF_);
\%env_hash = ( ${\$test->cons_env} );
\$env_hash{CPPPATH} = ['src', 'include'];
\$env = new cons ( \%env_hash );
Export qw( env );
Build qw(
	src/Conscript
);
_EOF_

$test->write(['repository', 'src', 'Conscript'], <<_EOF_);
Import qw( env );
Program \$env '$xxx_exe', qw (
	main.c
);
_EOF_

$test->write(['repository', 'include', 'my_string.h'], <<'_EOF_');
#define	MY_STRING	"repository/include/my_string.h"
_EOF_

$test->write(['repository', 'src', 'include.h'], <<'_EOF_');
#include <my_string.h>
#define	LOCAL_STRING	"repository/src/include.h"
_EOF_

$test->write(['repository', 'src', 'main.c'], <<'_EOF_');
#include <include.h>
main()
{
	printf("%s\n", MY_STRING);
	printf("%s\n", LOCAL_STRING);
	printf("repository/src/main.c\n");
	exit (0);
}
_EOF_


#
$test->run('chdir' => 'repository', targets => ".");

$test->execute(prog => $repository_src_xxx, stdout => <<_EOF_);
repository/include/my_string.h
repository/src/include.h
repository/src/main.c
_EOF_

# Make the repository non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository', 0);

#
$test->up_to_date('chdir' => 'work', flags => $flags, targets => ".");

$test->write(['work', 'include', 'my_string.h'], <<'_EOF_');
#define	MY_STRING	"work/include/my_string.h"
_EOF_

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_src_xxx, stdout => <<_EOF_);
work/include/my_string.h
repository/src/include.h
repository/src/main.c
_EOF_

$test->write(['work', 'src', 'include.h'], <<'_EOF_');
#include <my_string.h>
#define	LOCAL_STRING	"work/src/include.h"
_EOF_

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_src_xxx, stdout => <<_EOF_);
work/include/my_string.h
work/src/include.h
repository/src/main.c
_EOF_

$test->unlink($work_include_my_string_h);

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_src_xxx, stdout => <<_EOF_);
repository/include/my_string.h
work/src/include.h
repository/src/main.c
_EOF_

#
$test->pass;
__END__
