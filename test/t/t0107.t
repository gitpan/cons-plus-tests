#! /usr/bin/env perl
#
#	Create two repository subdirectories with a single .c and
#	Construct file in the "old" repository.  Invoke cons -R -R
#	in a work subdirectory.  Check that it built correctly.
#	Create a .c in the "new" repository; invoke cons -R -R;
#	check that the executable built with the new .c file.
#	Create a .c in the work subdirectory; cons -R -R; check
#	that the executable built with the work .c file.  Update
#	both repository .c files; cons -R -R; check that the
#	executable still uses the work .c file.  Remove the work
#	.c file; cons -R -R; check that the executable uses the
#	new repository .c file.  Remove the new repository .c file;
#	cons -R -R; check that the executable uses the old repository
#	.c file.
#

# $Id: t0107.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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
use File::Copy;

$test = Test::Cmd::Cons->new('string' => 'single-module Program, multiple -R');

$test->subdir('repository.NEW', 'repository.OLD', 'work');

#
$foo_exe = "foo$_exe";
$workpath_repository_NEW = $test->workpath('repository.NEW');
$workpath_repository_OLD = $test->workpath('repository.OLD');
$work_foo = $test->catfile('work', 'foo');
$work_foo_c = $test->catfile('work', 'foo.c');
$repository_NEW_Construct = $test->catfile('repository.NEW', 'Construct');
$repository_NEW_foo_c = $test->catfile('repository.NEW', 'foo.c');
$repository_OLD_Construct = $test->catfile('repository.OLD', 'Construct');

$flags = "-R $workpath_repository_NEW -R $workpath_repository_OLD";

#
$test->write(['repository.OLD', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$foo_exe', 'foo.c';
_EOF_

#cp repository.OLD/Construct repository.NEW/construct
File::Copy::copy($repository_OLD_Construct, $repository_NEW_Construct);


$test->write(['repository.OLD', 'foo.c'], <<'_EOF_');
main()
{
	printf("repository.OLD/foo.c\n");
	exit (0);
}
_EOF_


# Make the repositories non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository.NEW', 0);

$test->writable('repository.OLD', 0);

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository.OLD/foo.c
_EOF_

$test->up_to_date('chdir' => 'work', flags => $flags, targets => ".");

$test->writable('repository.NEW', 1);

$test->write(['repository.NEW', 'foo.c'], <<'_EOF_');
main()
{
	printf("repository.NEW/foo.c\n");
	exit (0);
}
_EOF_

$test->writable('repository.NEW', 0);

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository.NEW/foo.c
_EOF_

$test->up_to_date('chdir' => 'work', flags => $flags, targets => ".");

$test->write(['work', 'foo.c'], <<'_EOF_');
main()
{
	printf("work/foo.c\n");
	exit (0);
}
_EOF_

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
work/foo.c
_EOF_

$test->up_to_date('chdir' => 'work', flags => $flags, targets => ".");

$test->writable('repository.NEW', 1);

$test->write(['repository.NEW', 'foo.c'], <<'_EOF_');
main()
{
	printf("repository.NEW/foo.c again\n");
	exit (0);
}
_EOF_

$test->writable('repository.NEW', 0);

$test->writable('repository.OLD', 1);

$test->write(['repository.OLD', 'foo.c'], <<'_EOF_');
main()
{
	printf("repository.OLD/foo.c again\n");
	exit (0);
}
_EOF_

$test->writable('repository.OLD', 0);

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
work/foo.c
_EOF_

$test->up_to_date('chdir' => 'work', flags => $flags, targets => ".");

$test->unlink($work_foo_c);

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository.NEW/foo.c again
_EOF_

$test->up_to_date('chdir' => 'work', flags => $flags, targets => ".");

$test->writable('repository.NEW', 1);

$test->unlink($repository_NEW_foo_c);

$test->writable('repository.NEW', 0);

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository.OLD/foo.c again
_EOF_

$test->up_to_date('chdir' => 'work', flags => $flags, targets => ".");

#
$test->pass;
__END__
