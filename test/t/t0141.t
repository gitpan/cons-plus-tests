#! /usr/bin/env perl
#
#	Create subdirectories work, foo, and bar.  Construct file
#	specifies a CPPPATH of .:zzz, a Prgoram that builds a single
#	.c file, and a Command that prints %CCCOM to an output
#	file.  In the work directory, invoke cons -R foo -R work
#	-R bar.  Examine the CCCOM output to make sure that the list
#	of directories specified via -I flags properly excludes the
#	work subdirectory in which we executed.
#
#	NOTE:  THIS TEST EXAMINES THE ACTIONS USED TO BUILD FILES.
#

# $Id: t0141.t,v 1.4 2000/06/01 22:00:50 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => '-R, strip current directory');

$test->subdir('foo', 'bar', 'work');

#
$workpath_foo = $test->workpath('foo');
$workpath_foo_zzz = $test->workpath('foo', 'zzz');
$workpath_bar = $test->workpath('bar');
$workpath_bar_zzz = $test->workpath('bar', 'zzz');
$workpath_work = $test->workpath('work');
$work_CCCOM_out = $test->catfile('work', 'CCCOM.out');

#
$test->write(['work', 'Construct'], <<_EOF_);
\%env_hash = ( ${\$test->cons_env} );
\$env_hash{CPPPATH} = ['.', 'zzz'];
\$env = new cons ( \%env_hash );
Program \$env 'foo', 'foo.c';
Command \$env 'CCCOM.out', 'foo', qq(
	\Q$^X\E -e "print '\\Q\%CCCOM\\E', \\\\"\\\\n\\\\"" > %>
);
_EOF_

$test->write(['work', 'foo.c'], <<'_EOF_');
main()
{
	printf("work/foo.c");
}
_EOF_

$test->run('chdir' => 'work', flags => "-R $workpath_foo -R $workpath_work -R $workpath_bar", targets => ".");

$test->read(\$result, $work_CCCOM_out);
$result = join("\n", grep(s#^[-/]I(.*)#$1#, split(/\s/, $result))) . "\n";
$test->fail($result ne <<_EOF_ => sub {print STDERR "Actual STDOUT =====\n", $result});
.
$workpath_foo
$workpath_bar
zzz
$workpath_foo_zzz
$workpath_bar_zzz
_EOF_

#
$test->pass;
__END__
