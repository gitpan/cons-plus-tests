#! /usr/bin/env perl
#
#	In the repository subdirectory, define two separate
#	executables to be compiled from single .c files via separate
#	Conscript files in separate subdirectories.  Invoke cons
#	in the work subdirectory, pruning the build to one of the
#	subdirectories ('+subdir') and make sure only the executable
#	in that subdirectory gets built.  Invoke cons in the work
#	subdirectory with '.' as an argument.  Make sure the other
#	subdirectory's executable now got built, too.
#

# $Id: t0133.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => 'build pruning, -R');


$test->subdir('work',
		'repository',
		['repository', 'foo'],
		['repository', 'bar']);

#
$foo_exe = "foo$_exe";
$bar_exe = "bar$_exe";
$workpath_repository = $test->workpath('repository');
$work_bar_bar = $test->catfile('work', 'bar', 'bar');
$work_foo_foo = $test->catfile('work', 'foo', 'foo');

$flags = "-R $workpath_repository";

#
$test->write(['repository', 'Construct'], <<'_EOF_');
Build qw (
	foo/Conscript
	bar/Conscript
);
_EOF_

$test->write(['repository', 'foo', 'Conscript'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$foo_exe', 'foo.c';
_EOF_

$test->write(['repository', 'foo', 'foo.c'], <<'_EOF_');
main()
{
	printf("repository/foo/foo.c\n");
	exit (0);
}
_EOF_

$test->write(['repository', 'bar', 'Conscript'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$bar_exe', 'bar.c';
_EOF_

$test->write(['repository', 'bar', 'bar.c'], <<'_EOF_');
main()
{
	printf("repository/bar/bar.c\n");
	exit (0);
}
_EOF_


#
# Make the repository non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository', 0);

$test->run('chdir' => 'work', flags => "$flags +bar", targets => ".");
$test->must_not_exist(['work', 'foo', $foo_exe]);
$test->execute(prog => $work_bar_bar, stdout => <<_EOF_);
repository/bar/bar.c
_EOF_

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_foo_foo, stdout => <<_EOF_);
repository/foo/foo.c
_EOF_

#
$test->pass;
__END__
