#! /usr/bin/env perl
#
#	Create a work subdirectory and a repository subdirectory.
#	The work subdirectory contains four .c files and a Construct
#	file with Repository pointing to a non-existant repository.
#	Invoke cons in the work subdirectory.  Make sure the
#	generated executable was built successfully from the work
#	subdirectory .c files.
#

# $Id: t0101.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => 'Repository, no repository directory');

$test->subdir('work');

#
$workpath_no_repository = $test->workpath('no_repository');

$foo_exe = "foo$_exe";
$work_foo = $test->catfile('work', 'foo');

#
$test->write(['work', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Repository '$workpath_no_repository';
Program \$env '$foo_exe', qw (
	aaa.c
	bbb.c
	ccc.c
	main.c
);
_EOF_

$test->write(['work', 'aaa.c'], <<'_EOF_');
aaa()
{
	printf("work/aaa.c\n");
}
_EOF_

$test->write(['work', 'bbb.c'], <<'_EOF_');
bbb()
{
	printf("work/bbb.c\n");
}
_EOF_

$test->write(['work', 'ccc.c'], <<'_EOF_');
ccc()
{
	printf("work/ccc.c\n");
}
_EOF_

$test->write(['work', 'main.c'], <<'_EOF_');
main()
{
	aaa();
	bbb();
	ccc();
	printf("work/main.c\n");
	exit (0);
}
_EOF_

#
$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
work/aaa.c
work/bbb.c
work/ccc.c
work/main.c
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

#
$test->pass;
__END__
