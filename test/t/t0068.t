#! /usr/bin/env perl
#
#	Build three Programs, one named "0", one named "0" in a
#	subdirectory, and one in a subdirectory named "0".
#

# $Id: t0068.t,v 1.3 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => '"0" as file and directory name');

$test->subdir('sub1', 'sub2');

#
$zero_exe = "0$_exe";
$sub1_zero = $test->catfile('sub1', "0");
$sub1_zero_exe = $test->catfile('sub1', "0$_exe");
$sub2_zero_foo = $test->catfile('sub2', '0', "foo");
$sub2_zero_foo_exe = $test->catfile('sub2', '0', "foo$_exe");

#
$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$zero_exe', 'zero.c';
Program \$env '$sub1_zero_exe', 'zero.c';
Program \$env '$sub2_zero_foo_exe', 'foo.c';
_EOF_

$test->write('zero.c', <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("zero.c\n");
	exit (0);
}
_EOF_

$test->write('foo.c', <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("foo.c\n");
	exit (0);
}
_EOF_

#
$test->run(targets => ".");

#$test->execute(prog => "0", stdout => <<_EOF_);
#zero.c
#_EOF_

$test->execute(prog => $sub1_zero, stdout => <<_EOF_);
zero.c
_EOF_

$test->execute(prog => $sub2_zero_foo, stdout => <<_EOF_);
foo.c
_EOF_

#
$test->pass;
__END__
