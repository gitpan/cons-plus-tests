#! /usr/bin/env perl
#
#	Compile a Program from a source .c file.  Make the source file
#	non-readable, and change the Conscript file to generate the source
#	file from another input file.  Rebuild the Program, making sure
#	that the inability to read the .c file doesn't cause a failure.
#

# $Id: t0066.t,v 1.3 2000/06/01 22:00:45 knight Exp $

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

$test = Test::Cmd::Cons->new(string => 'source file => unreadable derived file');

#
$aaa_exe = "aaa$_exe";

#
$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$aaa_exe', 'aaa.c';
_EOF_

$test->write('aaa.c', <<'_EOF_');
main()
{
	printf("aaa.c\n");
	exit (0);
}
_EOF_

$test->run(targets => ".");

$test->execute(prog => "aaa", stdout => <<_EOF_);
aaa.c
_EOF_

$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Program \$env '$aaa_exe', 'aaa.c';
Command \$env 'aaa.c', 'aaa.in', qq(
	\Q$^X\E -e "use File::Copy; copy('%<', '%>'); exit 0"
);
_EOF_

$ret = chmod(000, "aaa.c");
$test->no_result(! $ret);

$test->write('aaa.in', <<'_EOF_');
main()
{
	printf("aaa.in\n");
	exit (0);
}
_EOF_

$test->run(targets => ".");

$test->execute(prog => "aaa", stdout => <<_EOF_);
aaa.in
_EOF_

#
$test->pass;
__END__
