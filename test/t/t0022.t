#! /usr/bin/env perl
#
#	Define two separate executables to be compiled from single
#	.c files via separate Conscript files in separate
#	subdirectories.  Prune the build to one of the subdirectories
#	('+subdir') and make sure only the executable in that
#	subdirectory gets built.  Invoke cons with '.' as an
#	argument.  Make sure the other subdirectory's executable
#	got built, too.
#

# $Id: t0022.t,v 1.3 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => 'build pruning');

$test->subdir('foo', 'bar');

#
$foo_exe = "foo$_exe";
$bar_exe = "bar$_exe";
$foo_Conscript = $test->catfile('foo', 'Conscript');
$bar_Conscript = $test->catfile('bar', 'Conscript');
$foo_foo = $test->catfile('foo', 'foo');
$foo_foo_exe = $test->catfile('foo', $foo_exe);
$bar_bar = $test->catfile('bar', 'bar');

#
$test->write('Construct', <<_EOF_);
Build qw (
	$foo_Conscript
	$bar_Conscript
);
_EOF_

$test->write($foo_Conscript, <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$foo_exe', 'foo.c';
_EOF_

$test->write(['foo', 'foo.c'], <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("foo/foo.c\n");
	exit (0);
}
_EOF_

$test->write($bar_Conscript, <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$bar_exe', 'bar.c';
_EOF_

$test->write(['bar', 'bar.c'], <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("bar/bar.c\n");
	exit (0);
}
_EOF_

#
$test->run(flags => "+bar", targets => ".");
$test->must_not_exist($foo_foo_exe);

$test->execute(prog => $bar_bar, stdout => <<_EOF_);
bar/bar.c
_EOF_

#
$test->run(targets => ".");

$test->execute(prog => $foo_foo, stdout => <<_EOF_);
foo/foo.c
_EOF_

#
$test->pass;
__END__
