#! /usr/bin/env perl
#
#	Define two executables to be built from duplicate .c files.
#	Define a built environment with CFLAGS dependent on %COPT.
#	Clone the environment, changing only %COPT.  Built one
#	executable with one environment and the other with the
#	other, making sure that each executable used the correct
#	%COPT value for its environment.
#

# $Id: t0024.t,v 1.3 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => 'clone');

#
$foo1_exe = "foo1$_exe";
$foo2_exe = "foo2$_exe";

#
$test->write('Construct', <<_EOF_);
\%env_hash = ( ${\$test->cons_env} );
\$env_hash{COPT} = '-DENV=1';
\$env_hash{CFLAGS} .= ' -DSTRING=\\\"FOO\\\" %COPT';
\$env1 = new cons ( \%env_hash );
\$env2 = \$env1->clone(
	COPT	=> '-DENV=2',
);
Program \$env1 '$foo1_exe', 'foo1.c';
Program \$env2 '$foo2_exe', 'foo2.c';
_EOF_

$test->write('foo1.c', <<'_EOF_');
int
main(int argc, char *argv[])
{
	printf("This is the fooX.c file, ENV = %d:  %s.\n", ENV, STRING);
	exit (0);
}
_EOF_

$test->copy('foo1.c', 'foo2.c');

#
$test->run(targets => ".");

$test->execute(prog => 'foo1', stdout => <<_EOF_);
This is the fooX.c file, ENV = 1:  FOO.
_EOF_

$test->execute(prog => 'foo2', stdout => <<_EOF_);
This is the fooX.c file, ENV = 2:  FOO.
_EOF_

#
$test->pass;
__END__
