#! /usr/bin/env perl
#
#	Compile a single executable from a single repository .c
#	file which includes a single .h file from one of two
#	repository subdirectories.  Both subdirectories have the
#	same-named .h file.  Compile the executable twice, once
#	with the one subdirectory first in CPPPATH, then with the
#	other subdirectory first.
#

# $Id: t0123.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => 'CPPPATH, -R');

$test->subdir('work',
		['work', 'zark'],
		'repository',
		['repository', 'include'],
		['repository', 'zark']);

#
$foo_exe = "foo$_exe";
$workpath_repository = $test->workpath('repository');
$work_foo = $test->catfile('work', 'foo');

$flags = "-R $workpath_repository";

#
$test->write(['repository', 'foo.c'], <<'_EOF_');
#include <foo.h>
main()
{
	printf(STRING);
	exit (0);
}
_EOF_


$test->write(['repository', 'include', 'foo.h'], <<'_EOF_');
#define	STRING	"repository/include/foo.h\n"
_EOF_

$test->write(['repository', 'zark', 'foo.h'], <<'_EOF_');
#define	STRING	"repository/zark/foo.h\n"
_EOF_

$test->write(['work', 'zark', 'foo.h'], <<'_EOF_');
#define	STRING	"work/zark/foo.h\n"
_EOF_

$test->write(['repository', 'Construct'], <<_EOF_);
\%env_hash = ( ${\$test->cons_env} );
\$env_hash{CPPPATH} = ['include', 'zark'];
\$env = new cons ( \%env_hash );
Program \$env '$foo_exe', 'foo.c';
_EOF_


#
# Make the repository non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository', 0);

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository/include/foo.h
_EOF_

$test->write(['work', 'Construct'], <<_EOF_);
\%env_hash = ( ${\$test->cons_env} );
\$env_hash{CPPPATH} = ['zark', 'include'];
\$env = new cons ( \%env_hash );
Program \$env '$foo_exe', 'foo.c';
_EOF_

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
work/zark/foo.h
_EOF_

#
$test->pass;
__END__
