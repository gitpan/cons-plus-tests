#! /usr/bin/env perl
#
#	Create a Construct file that Builds Conscript.	Create a Conscript
#	file that Builds "foo/Conscript" and "foo/bar/Conscript".  Create
#	"foo/Conscript" that creates "bar" via a Command (copying another
#	file into it).	Run Cons; look for the error that "foo/bar" was
#	already a directory by the time it got to the Command line in the
#	subsidiary Conscript file.  Reverse the order:	Create another
#	Conscript file that createes "foo/bar" via Command, and create
#	another "foo/Conscript" that Builds "bar/Conscript"; Run Cons;
#	look for the error that "foo/bar" was already a file by the time
#	it got to the Build line in the subsidiary Conscript file.
#

# $Id: t0070.t,v 1.4 2000/06/01 22:00:45 knight Exp $

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

use Test::Cmd::Cons;

$test = Test::Cmd::Cons->new(string => 'file/directory failures');

$test->subdir('foo', ['foo', 'bar']);

#
$foo_Conscript = $test->catfile('foo', 'Conscript');
$bar_Conscript = $test->catfile('bar', 'Conscript');
$foo_bar = $test->catfile('foo', 'bar');
$foo_bar_in = $test->catfile('foo', 'bar.in');
$foo_bar_Conscript = $test->catfile('foo', 'bar', 'Conscript');

#
# The output contains line numbers in the Construct/Conscript file.
# Since $test->cons_env can be set externally (via the CONSENV environment
# variable) and would have a varied number of lines, this would throw
# off our line counts.  Sidestep this by creating the Cons environment
# in the Construct file and exporting it to a Conscript file (in the
# same directory).  This way, the line numbers in the Conscript file
# stay constant regardless of how many entries CONSENV has.
$test->write('Construct', <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Export qw( env );
Build 'Conscript';
_EOF_

$test->write($foo_bar_Conscript, <<_EOF_);
_EOF_

#
$test->write('Conscript', <<_EOF_);
Import qw( env );
Build '$foo_Conscript';
Build '$foo_bar_Conscript';
_EOF_

#
$test->write($foo_Conscript, <<_EOF_);
Import qw( env );
Command \$env 'bar', 'bar.in', qq(
	\Q$^X\E -e "use File::Copy; copy('%<', '%>'); exit 0"
);
_EOF_

$test->run(targets => ".", fail => '$? == 0', stdout => <<_EOF_, stderr => <<_EOF_);
\Q${\$test->basename}\E: error in file "\Q$foo_Conscript\E":
	"\Q$foo_bar\E" already in use as a dir before cons::Command on line 2,
		defined by script::Build in Conscript, line 3
_EOF_
\Q${\$test->basename}\E: script errors encountered: construction aborted
_EOF_

#
$test->write('Conscript', <<_EOF_);
Import qw( env );
Build '$foo_Conscript';
Command \$env '$foo_bar', '$foo_bar_in', qq(
	\Q$^X\E -e "use File::Copy; copy('%<', '%>'); exit 0"
);
_EOF_

$test->write($foo_Conscript, <<_EOF_);
Import qw( env );
Build '$bar_Conscript';
_EOF_

$test->run(targets => ".", fail => '$? == 0', stdout => <<_EOF_, stderr => <<_EOF_);
\Q${\$test->basename}\E: error in file "\Q$foo_Conscript\E":
	"\Q$foo_bar\E" already in use as a file before script::Build on line 2,
		defined by cons::Command in Conscript, line 3
_EOF_
\Q${\$test->basename}\E: script errors encountered: construction aborted
_EOF_

#
$test->pass;
__END__
