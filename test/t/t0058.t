#! /usr/bin/env perl
#
#	Create a Construct and subdirectory Conscript file each of
#	which builds a single Program.  Execute Cons from the
#	subdirectory; make sure nothing was built.  Execute Cons -t
#	from the subdirectory; make sure it only built the
#	program in the subdirectory.  Build the entire tree.
#	Execute Cons -t -r from the subdirectory; make sure it only
#	removed the program in the subdirectory.  Cons -r
#	the entire tree.  Remove the Construct file.  Execute
#	Cons -t from the subdirectory; make sure it fails when
#	it can't find the Construct file.
#

# $Id: t0058.t,v 1.6 2000/06/16 20:40:40 knight Exp $

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

$test = Test::Cmd::Cons->new(string => '-t');

$test->subdir('export', 'subdir');

#
$foo_exe = "foo$_exe";
$bar_exe = "bar$_exe";
$export_foo = $test->catfile('export', 'foo');
$export_foo_exe = $test->catfile('export', $foo_exe);
$subdir_Conscript = $test->catfile('subdir', 'Conscript');
$subdir_bar = $test->catfile('subdir', 'bar');
$subdir_bar_exe = $test->catfile('subdir', $bar_exe);

#
$test->write("Construct", <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$foo_exe', 'foo.c';
Install \$env 'export', '$foo_exe';
Build qw(
	$subdir_Conscript
);
_EOF_

$test->write($subdir_Conscript, <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$bar_exe', 'bar.c';
_EOF_

$test->write('foo.c', <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("foo.c\n");
	exit (0);
}
_EOF_

$test->write(['subdir', 'bar.c'], <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("subdir/bar.c\n");
	exit (0);
}
_EOF_

#
$test->run('chdir' => 'subdir', targets => ".");
$test->must_not_exist($foo_exe);
$test->must_not_exist($export_foo_exe);
$test->must_not_exist($subdir_bar_exe);

$test->run('chdir' => 'subdir', flags => '-t', targets => ".");
$test->must_not_exist($foo_exe);
$test->must_not_exist($export_foo_exe);

$test->execute(prog => $subdir_bar, stdout => <<_EOF_);
subdir/bar.c
_EOF_

$test->run(targets => ".");

$test->execute(prog => 'foo', stdout => <<_EOF_);
foo.c
_EOF_

$test->execute(prog => $export_foo, stdout => <<_EOF_);
foo.c
_EOF_

$test->run('chdir' => 'subdir', flags => '-t -r', targets => ".");
$test->must_exist($foo_exe);
$test->must_exist($export_foo_exe);
$test->must_not_exist($subdir_bar_exe);

$test->run(flags => '-r', targets => ".");
$test->must_not_exist($foo_exe);
$test->must_not_exist($export_foo_exe);

$test->run(flags => '-t', targets => "export");
$test->must_not_exist($subdir_bar_exe);

$test->execute(prog => $export_foo, stdout => <<_EOF_);
foo.c
_EOF_

$test->unlink('Construct');

$test->run('chdir' => 'subdir', flags => '-t', targets => ".", fail => '$? == 0'); # expect failure

$test->pass;
__END__
