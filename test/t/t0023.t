#! /usr/bin/env perl
#
#	Define an executable to be built from a single .c file in the
#	local directory.  The .c files prints a single string to be
#	supplied via '-DSTRING=' from CFLAGS in the build environment.
#	Create two override files that change CFLAGS when generating the
#	.o file.  Invoke cons; make sure the executable is built with
#	the default STRING value.  Invoke cons with the firts override
#	file (-o over1); make sure the executable is built with the
#	first overridden STRING value.	Invoke cons with the second
#	override file (-oover2); make sure the executable is build
#	with the second overriddent STRING value.  Invoke cons again,
#	without the override; make sure the executable has reverted to
#	the original STRING value.
#

# $Id: t0023.t,v 1.3 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => '-o overrides');

#
$foo_exe = "foo$_exe";

#
$test->write('Construct', <<_EOF_);
\%env_hash = ( ${\$test->cons_env} );
\$env_hash{COPT} = '-DSTRING=\\\"FOO\\\"';
\$env_hash{CFLAGS} .= ' %COPT';
\$env = new cons ( \%env_hash );
Program \$env '$foo_exe', 'foo.c';
_EOF_

$test->write('foo.c', <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("foo.c:  %s\n", STRING);
	exit (0);
}
_EOF_

$test->write('over1', <<_EOF_);
Override '\\$_o\$', COPT => '-DSTRING=\\"OVERRIDE_1\\"';
_EOF_

$test->write('over2', <<_EOF_);
Override '\\$_o\$', COPT => '-DSTRING=\\"OVERRIDE_2\\"';
_EOF_

#
$test->run(targets => ".");

$test->execute(prog => 'foo', stdout => <<_EOF_);
foo.c:  FOO
_EOF_

#
$test->run(flags => "-o over1", targets => ".");

$test->execute(prog => 'foo', stdout => <<_EOF_);
foo.c:  OVERRIDE_1
_EOF_

#
$test->run(flags => "-o over2", targets => ".");

$test->execute(prog => 'foo', stdout => <<_EOF_);
foo.c:  OVERRIDE_2
_EOF_

$test->run(targets => ".");

$test->execute(prog => 'foo', stdout => <<_EOF_);
foo.c:  FOO
_EOF_

#
$test->pass;
__END__
