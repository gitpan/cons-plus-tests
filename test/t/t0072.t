#! /usr/bin/env perl
#
#	Compile a single executable from a single .c file in the
#	local directory.  After making sure it builds correctly,
#	re-run Cons with 'perl -Mstrict" and make sure we don't
#	get any errors or warnings.
#

# $Id: t0072.t,v 1.3 2000/06/26 16:56:57 knight Exp $

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

use Test::Cmd::Cons qw($_exe $_o);

$test = Test::Cmd::Cons->new(string => '-Mstrict');

# XXX Short-circuit this test for now.
#     We're leaving this file checked-in to avoid extra work
#     when we re-apply Johan Holmberg's -Mstrict patch after
#     the FSF receives his copyright assignment.  In the
#     meantime, just make the test pass.
$test->pass;
__END__

$CC = $test->cons_env_val('CC') || 'cc';
$LINK = $test->cons_env_val('LINK') || $CC;

#
$interpreter = $test->interpreter;

#
$foo_exe = "foo$_exe";
$foo_o = "foo$_o";

#
$test->write("Construct", <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$foo_exe', 'foo.c';
_EOF_

$test->write("foo.c", <<'_EOF_');
main(int argc, char *argv[])
{
	printf("foo.c\n");
	exit (0);
}
_EOF_

#
$test->run(targets => ".");

$test->execute(prog => 'foo', stdout => <<_EOF_);
foo.c
_EOF_

$test->up_to_date(targets => ".");

$test->run(flags => "-r", targets => ".");

#
$test->interpreter("$interpreter -Mstrict");

$test->run(targets => ".", stdout => <<_EOF_, stderr => <<_EOF_);
$CC .*\\b\Qfoo.c\E\\b.*\Q$foo_o\E\\b.*
$LINK .*$foo_exe\\b.*\\b\Q$foo_o\E\\b.*
_EOF_
_EOF_

$test->up_to_date(targets => ".");

$test->pass;
__END__
