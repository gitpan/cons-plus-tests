#! /usr/bin/env perl
#
#	Create a work subdirectory and two repository subdirectories.
#	The work subdirectory contains the Construct file with
#	Repository pointing to first the "new" repository and then
#	the "old" repository.  The "old" repository contains a
#	single .c file.  Invoke cons in the work subdirectory.
#	Check that the executable was generated correctly from the
#	"old" repository .c file.  Create a same-named .c file in
#	the "new" repository.  Invoke cons in the work subdirectory.
#	Check that the executable was re-generated correctly from
#	the "new" repository .c file.  Create a same-named .c file
#	in the work subdirectory.  Invoke cons again.  Check that
#	the executable was re-generated correctly from the work
#	subdirectory .c file.  Update both the "old" and "new"
#	repository .c files.  Invoke cons again.  Check that the
#	executable is still from the work subdirectory .c file.
#	Remove the work subdirectory .c file.  Invoke cons again.
#	Check that the executable has been rebuilt with the "new"
#	repository .c file.  Remove the "new" repository .c file.
#	Invoke cons again.  Check that the executable has been
#	rebuilt with the "old" repository .c file.
#

# $Id: t0103.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => 'single-module Repository Program, multiple repositories');

$test->subdir('repository.NEW', 'repository.OLD', 'work');

#
$foo_exe = "foo$_exe";
$workpath_repository_NEW = $test->workpath('repository.NEW');
$workpath_repository_OLD = $test->workpath('repository.OLD');
$work_foo = $test->catfile('work', 'foo');
$work_foo_c = $test->catfile('work', 'foo.c');
$repository_NEW_foo_c = $test->catfile('repository.NEW', 'foo.c');

#
$test->write(['work', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Repository qw (
	$workpath_repository_NEW
	$workpath_repository_OLD
);
Program \$env '$foo_exe', 'foo.c';
_EOF_


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

$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository.OLD/foo.c
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

$test->writable('repository.NEW', 1);

$test->write(['repository.NEW', 'foo.c'], <<'_EOF_');
main()
{
	printf("repository.NEW/foo.c\n");
	exit (0);
}
_EOF_

$test->writable('repository.NEW', 0);

$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository.NEW/foo.c
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

$test->write(['work', 'foo.c'], <<'_EOF_');
main()
{
	printf("work/foo.c\n");
	exit (0);
}
_EOF_

$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
work/foo.c
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

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

$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
work/foo.c
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

$test->unlink($work_foo_c);


$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository.NEW/foo.c again
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

$test->writable('repository.NEW', 1);

$test->unlink($repository_NEW_foo_c);

$test->writable('repository.NEW', 0);

$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository.OLD/foo.c again
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

#
$test->pass;
__END__
