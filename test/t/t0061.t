#! /usr/bin/env perl
#
#	Create two Programs, one in a subdirectory, each from three
#	object files.  For each Program, the object files are listed
#	via the Objects method, one in the local directory, one in
#	a subdirectory, and the last in sub-subdirectory.  Build the
#	Programs and make sure they built correctly.
#

# $Id: t0061.t,v 1.3 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => 'Objects');

$test->subdir('sub', ['sub', 'dir'],
		'src', ['src', 'sub'],  ['src', 'sub', 'dir']);

#
$foo_exe = "foo$_exe";
$bar_exe = "bar$_exe";

$src_bar = $test->catfile('src', 'bar');
$src_Conscript = $test->catfile('src', 'Conscript');

$sub_aaa_c = $test->catfile('sub', 'aaa.c');
$sub_dir_bbb_c = $test->catfile('sub', 'dir', 'bbb.c');
$sub_ccc_c = $test->catfile('sub', 'ccc.c');
$sub_dir_ddd_c = $test->catfile('sub', 'dir', 'ddd.c');

#
$test->write("Construct", <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Export qw( env );
\@ofiles = Objects \$env qw(
	foo.c
	$sub_aaa_c
	$sub_dir_bbb_c
);
Program \$env '$foo_exe', \@ofiles;
Build '$src_Conscript';
_EOF_

$test->write($src_Conscript, <<_EOF_);
Import qw( env );
\@ofiles = Objects \$env qw(
	bar.c
	$sub_ccc_c
	$sub_dir_ddd_c
);
Program \$env '$bar_exe', \@ofiles;
_EOF_

$test->write('foo.c', <<'_EOF_');
extern void aaa(void);
extern void bbb(void);
int
main(int argc, char *argv[])
{
	aaa();
	bbb();
	printf("foo.c\n");
	exit (0);
}
_EOF_

$test->write(['sub', 'aaa.c'], <<'_EOF_');
void
aaa(void)
{
	printf("sub/aaa.c\n");
}
_EOF_

$test->write(['sub', 'dir', 'bbb.c'], <<'_EOF_');
void
bbb(void)
{
	printf("sub/dir/bbb.c\n");
}
_EOF_

$test->write(['src', 'bar.c'], <<'_EOF_');
extern void ccc(void);
extern void ddd(void);
int
main(int argc, char *argv[])
{
	ccc();
	ddd();
	printf("src/bar.c\n");
	exit (0);
}
_EOF_

$test->write(['src', 'sub', 'ccc.c'], <<'_EOF_');
void
ccc(void)
{
	printf("src/sub/ccc.c\n");
}
_EOF_

$test->write(['src', 'sub', 'dir', 'ddd.c'], <<'_EOF_');
void
ddd(void)
{
	printf("src/sub/dir/ddd.c\n");
}
_EOF_

#
$test->run(targets => ".");

$test->execute(prog => 'foo', stdout => <<_EOF_);
sub/aaa.c
sub/dir/bbb.c
foo.c
_EOF_

$test->execute(prog => $src_bar, stdout => <<_EOF_);
src/sub/ccc.c
src/sub/dir/ddd.c
src/bar.c
_EOF_

$test->pass;
__END__
