#! /usr/bin/env perl
#
#	Create a repository subdirectory.  The repository contains
#	four .c files and a Construct file.  The Construct files
#	specifies Repository {absolute path to repository subdirectory}.
#	Invoke cons in the repository subdirectory.  Check that
#	everything built correctly.  Invoke cons again; check that
#	everything was up-to-date and nothing was built.  Update
#	one .c file in the repository.  Invoke cons in the repository;
#	check that the new .c file was compiled and linked in.
#	Invoke cons again; check that everything was up-to-date
#	and nothing was built.
#

# $Id: t0113.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => 'multi-module Repository Program within repository');

$test->subdir('repository');

#
$foo_exe = "foo$_exe";
$workpath_repository = $test->workpath('repository');
$repository_foo = $test->catfile('repository', 'foo');

#
$test->write(['repository', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Repository '$workpath_repository';
Program \$env '$foo_exe', qw (
	aaa.c
	bbb.c
	ccc.c
	main.c
);
_EOF_

$test->write(['repository', 'aaa.c'], <<'_EOF_');
aaa()
{
	printf("repository/aaa.c\n");
}
_EOF_

$test->write(['repository', 'bbb.c'], <<'_EOF_');
bbb()
{
	printf("repository/bbb.c\n");
}
_EOF_

$test->write(['repository', 'ccc.c'], <<'_EOF_');
ccc()
{
	printf("repository/ccc.c\n");
}
_EOF_

$test->write(['repository', 'main.c'], <<'_EOF_');
main()
{
	aaa();
	bbb();
	ccc();
	printf("repository/main.c\n");
	exit (0);
}
_EOF_


#
$test->run('chdir' => 'repository', targets => ".");

$test->execute(prog => $repository_foo, stdout => <<_EOF_);
repository/aaa.c
repository/bbb.c
repository/ccc.c
repository/main.c
_EOF_

$test->up_to_date('chdir' => 'repository', targets => ".");

$test->write(['repository', 'bbb.c'], <<'_EOF_');
bbb()
{
	printf("repository/bbb.c #2\n");
}
_EOF_

$test->run('chdir' => 'repository', targets => ".");

$test->execute(prog => $repository_foo, stdout => <<_EOF_);
repository/aaa.c
repository/bbb.c #2
repository/ccc.c
repository/main.c
_EOF_

$test->up_to_date('chdir' => 'repository', targets => ".");

#
$test->pass;
__END__
