#! /usr/bin/env perl
#
#	Create a subdirectory with three .c files and Construct
#	file.  Create decoy .c files in the current directory.
#	Invoke cons -f subdir/Construct.  Check that it built
#	correctly in the subdirectory and didn't pick up any decoy
#	of the .c files.  Invoke cons -fsubdir/Construct again.
#	Check that nothing was rebuilt.
#

# $Id: t0028.t,v 1.3 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => '-f dir/Construct');

$test->subdir('subdir');

#
$foo_exe = "foo$_exe";
$subdir_Construct = $test->catfile('subdir', 'Construct');
$subdir_foo = $test->catfile('subdir', 'foo');

$test->write($subdir_Construct, <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$foo_exe', qw (
	aaa.c
	bbb.c
	main.c
);
_EOF_

$test->write('aaa.c', <<'_EOF_');
void
aaa(void)
{
	printf("aaa.c\n");
}
_EOF_

$test->write('bbb.c', <<'_EOF_');
void
bbb(void)
{
	printf("bbb.c\n");
}
_EOF_

$test->write(['subdir', 'aaa.c'], <<'_EOF_');
void
aaa(void)
{
	printf("subdir/aaa.c\n");
}
_EOF_

$test->write(['subdir', 'bbb.c'], <<'_EOF_');
void
bbb(void)
{
	printf("subdir/bbb.c\n");
}
_EOF_

$test->write(['subdir', 'main.c'], <<'_EOF_');
int
main(int argc, char *argv[])
{
	aaa();
	bbb();
	printf("subdir/main.c\n");
	exit (0);
}
_EOF_

#
$test->run(flags => "-f $subdir_Construct", targets => ".");

$test->execute(prog => $subdir_foo, stdout => <<_EOF_);
subdir/aaa.c
subdir/bbb.c
subdir/main.c
_EOF_

$test->up_to_date(flags => "-f $subdir_Construct", targets => ".");

#
$test->pass;
__END__
