#! /usr/bin/env perl
#
#	Compile a single executable from three .c files in the
#	local directory.
#

# $Id: t0002.t,v 1.3 2000/06/01 22:00:44 knight Exp $

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

$test = Test::Cmd::Cons->new(string => 'multiple-module Program');

#
$foo_exe = "foo$_exe";

#
$test->write("Construct", <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$foo_exe', qw (
	aaa.c
	bbb.c
	main.c
);
_EOF_

$test->write("aaa.c", <<'_EOF_');
void
aaa(void)
{
	printf("aaa.c\n");
}
_EOF_

$test->write("bbb.c", <<'_EOF_');
void
bbb(void)
{
	printf("bbb.c\n");
}
_EOF_

$test->write("main.c", <<'_EOF_');
extern void aaa(void);
extern void bbb(void);
int
main(int argc, char *argv[])
{
	aaa();
	bbb();
	printf("SUCCESS!\n");
	exit (0);
}
_EOF_

#
$test->run(targets => ".");

$test->execute(prog => 'foo', stdout => <<_EOF_);
aaa.c
bbb.c
SUCCESS!
_EOF_

$test->pass;
__END__
