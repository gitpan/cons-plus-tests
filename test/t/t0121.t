#! /usr/bin/env perl
#
#	Build a library from two modules in the repository, and
#	link it to another module in the repository to create a
#	repository executable.  Create a work copy of one of the
#	library modules, create a local library, link the repository
#	module to the local library.
#

# $Id: t0121.t,v 1.5 2000/06/01 22:00:45 knight Exp $

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

use Test::Cmd::Cons qw($_exe $_o $_a);

$test = Test::Cmd::Cons->new('string' => 'Library -R, link local .a with repository .o');

$test->subdir('work', 'repository');

#
$PREFLIB = $test->cons_env_val('PREFLIB');
$PREFLIB = 'lib' if ! defined($PREFLIB);

#
$foo_exe = "foo$_exe";
$workpath_repository = $test->workpath('repository');
$repository_foo = $test->catfile('repository', 'foo');
$work_foo = $test->catfile('work', 'foo');
$work_aaa_o = $test->catfile('work', "aaa$_o");
$work_bbb_o = $test->catfile('work', "bbb$_o");
$work_preflibfoo_a = $test->catfile('work', "${PREFLIB}foo$_a");
$work_main_o = $test->catfile('work', "main$_o");

$flags = "-R $workpath_repository";

#
$test->write(['repository', 'Construct'], <<_EOF_);
\$libenv = new cons ( ${\$test->cons_env} );
Library \$libenv '${PREFLIB}foo', qw (
	aaa.c
	bbb.c
);
\%env_hash = ( ${\$test->cons_env} );
\$env_hash{LIBPATH} = [ '.' ];
\$env_hash{LIBS} .= ' -lfoo';
\$fooenv = new cons ( \%env_hash );
Program \$fooenv '$foo_exe', 'main.c';
_EOF_

$test->write(['repository', 'main.c'], <<'_EOF_');
main()
{
	aaa();
	bbb();
	printf("repository/main.c\n");
	exit (0);
}
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


#
$test->run('chdir' => 'repository', targets => ".");

$test->execute(prog => $repository_foo, stdout => <<_EOF_);
repository/aaa.c
repository/bbb.c
repository/main.c
_EOF_

# Make the repository non-writable,
# so we'll detect if we try to write into it accidentally.
$test->writable('repository', 0);

$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository/aaa.c
repository/bbb.c
repository/main.c
_EOF_
$test->must_not_exist($work_aaa_o);
$test->must_not_exist($work_bbb_o);
$test->must_not_exist($work_preflibfoo_a);
$test->must_not_exist($work_main_o);

$test->write(['work', 'bbb.c'], <<'_EOF_');
bbb()
{
	printf("work/bbb.c\n");
}
_EOF_


$test->run('chdir' => 'work', flags => $flags, targets => ".");

$test->execute(prog => $work_foo, stdout => <<_EOF_);
repository/aaa.c
work/bbb.c
repository/main.c
_EOF_
$test->must_not_exist($work_aaa_o);
$test->must_not_exist($work_main_o);

#
$test->pass;
__END__
