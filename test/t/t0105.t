#! /usr/bin/env perl
#
#	Create a work subdirectory and two repository subdirectories.
#	The work subdirectory contains the Construct file with
#	Repository pointing to first the "new" repository and then
#	the "old" repository.  The "old" repository contains four
#	.c files.  Invoke cons in the work subdirectory.  Check
#	that the executable was generated correctly from the "old"
#	.c files.  Create one .c files in the "new" repository and
#	another in the work sbudirectory.  Invoke cons again.
#	Check that the executable was generated correctly...  Create
#	all the remaining files in the work subdirectory.  Invoke
#	cons again.  Check...  Remove two files from the work
#	subdirectory, one with the name of the "new" repository
#	file, one not.  Invoke cons again and check...  Remove the
#	remaining work files.  Invoke cons again and check...
#	Remove the last "new" repository .c file.  Invoke cons
#	again and check that we're back to all "old" repository
#	files.
#

# $Id: t0105.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => 'multi-module Repository Program, multiple repositories');

$test->subdir('repository.NEW', 'repository.OLD', 'work');

#
$foo_exe = "foo$_exe";
$workpath_repository_NEW = $test->workpath('repository.NEW');
$workpath_repository_OLD = $test->workpath('repository.OLD');
$work_foo = $test->catfile('work', 'foo');
$work_aaa_c = $test->catfile('work', 'aaa.c');
$work_bbb_c = $test->catfile('work', 'bbb.c');
$work_ccc_c = $test->catfile('work', 'ccc.c');
$work_main_c = $test->catfile('work', 'main.c');
$repository_NEW_bbb_c = $test->catfile('repository.NEW', 'bbb.c');

#
$test->write(['work', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Repository qw (
	$workpath_repository_NEW
	$workpath_repository_OLD
);
Program \$env '$foo_exe', qw (
	aaa.c
	bbb.c
	ccc.c
	main.c
);
_EOF_

$test->write(['repository.OLD', 'aaa.c'], <<'_EOF_');
aaa()
{
	printf("repository.OLD/aaa.c\n");
}
_EOF_

$test->write(['repository.OLD', 'bbb.c'], <<'_EOF_');
bbb()
{
	printf("repository.OLD/bbb.c\n");
}
_EOF_

$test->write(['repository.OLD', 'ccc.c'], <<'_EOF_');
ccc()
{
	printf("repository.OLD/ccc.c\n");
}
_EOF_

$test->write(['repository.OLD', 'main.c'], <<'_EOF_');
main()
{
	aaa();
	bbb();
	ccc();
	printf("repository.OLD/main.c\n");
	exit (0);
}
_EOF_

# Make the repositories non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository.NEW', 0);

$test->writable('repository.OLD', 0);

$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository.OLD/aaa.c
repository.OLD/bbb.c
repository.OLD/ccc.c
repository.OLD/main.c
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

$test->writable('repository.NEW', 1);

$test->write(['repository.NEW', 'bbb.c'], <<'_EOF_');
bbb()
{
	printf("repository.NEW/bbb.c\n");
}
_EOF_

$test->writable('repository.NEW', 0);

$test->write(['work', 'ccc.c'], <<'_EOF_');
ccc()
{
	printf("work/ccc.c\n");
}
_EOF_

$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository.OLD/aaa.c
repository.NEW/bbb.c
work/ccc.c
repository.OLD/main.c
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

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

$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
work/aaa.c
work/bbb.c
work/ccc.c
work/main.c
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

$test->unlink($work_aaa_c);

$test->unlink($work_bbb_c);

$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository.OLD/aaa.c
repository.NEW/bbb.c
work/ccc.c
work/main.c
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

$test->unlink($work_ccc_c);

$test->unlink($work_main_c);

$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository.OLD/aaa.c
repository.NEW/bbb.c
repository.OLD/ccc.c
repository.OLD/main.c
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

$test->writable('repository.NEW', 1);

$test->unlink($repository_NEW_bbb_c);

$test->writable('repository.NEW', 0);

$test->run('chdir' => 'work', targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository.OLD/aaa.c
repository.OLD/bbb.c
repository.OLD/ccc.c
repository.OLD/main.c
_EOF_

$test->up_to_date('chdir' => 'work', targets => ".");

#
$test->pass;
__END__
