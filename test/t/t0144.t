#! /usr/bin/env perl
#
#	Create four empty repository directories, and a work
#	Construct file that specifies Repository for two of them,
#	and then fetches the Repository_List and prints it to a
#	file.  Invoke cons; check that the list was printed correctly.
#	Invoke cons -R -R, check that the argument repositories
#	preced the Construct file repositories.  Re-create the
#	Construct file without the Repository method.  Invoke cons
#	-R -R -R, check that the repository list is correct despite
#	the lack of the Repository method.  Invoke cons without any
#	-R flags, check that the output lists no repositories.
#

# $Id: t0144.t,v 1.5 2000/06/01 22:00:50 knight Exp $

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

$test = Test::Cmd::Cons->new('string' => 'Repository_List');

$test->subdir('repository.1',
		'repository.2',
		'repository.3',
		'repository.4',
		'work');

#
$workpath_repository_1 = $test->workpath('repository.1');
$workpath_repository_2 = $test->workpath('repository.2');
$workpath_repository_3 = $test->workpath('repository.3');
$workpath_repository_4 = $test->workpath('repository.4');
$work_replist_1_out = $test->catfile('work', 'replist-1.out');
$work_replist_2_out = $test->catfile('work', 'replist-2.out');
$work_replist_3_out = $test->catfile('work', 'replist-3.out');
$work_replist_4_out = $test->catfile('work', 'replist-4.out');

#
$test->write(['work', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
Repository qw (
	$workpath_repository_2
	$workpath_repository_1
);
\$rep_list_str = join("\\\\n", map("\\Q\$_\\E", Repository_List));
\$repository_out = "replist-\$ARG{TEST}.out";
Command \$env \$repository_out, 'Construct', qq(
	\Q$^X\E -e "print \\\\"\$rep_list_str\\\\n\\\\"" > %>
);
_EOF_


# Make the repositories non-writable,
# so we'll detect if we try to write into them accidentally.
$test->writable('repository.1', 0);
$test->writable('repository.2', 0);
$test->writable('repository.3', 0);
$test->writable('repository.4', 0);

#
$test->run('chdir' => 'work', flags => "TEST=1", targets => ".");
$test->file_matches($work_replist_1_out, <<_EOF_);
\Q$workpath_repository_2\E
\Q$workpath_repository_1\E
_EOF_

$test->run('chdir' => 'work', flags => "-R $workpath_repository_4 -R $workpath_repository_3 TEST=2", targets => ".");
$test->file_matches($work_replist_2_out, <<_EOF_);
\Q$workpath_repository_4\E
\Q$workpath_repository_3\E
\Q$workpath_repository_2\E
\Q$workpath_repository_1\E
_EOF_

$test->write(['work', 'Construct'], <<_EOF_);
\$env = new cons ( ${\$test->cons_env} );
\$rep_list_str = join("\\\\n", map("\\Q\$_\\E", Repository_List));
\$repository_out = "replist-\$ARG{TEST}.out";
Command \$env \$repository_out, 'Construct', qq(
	\Q$^X\E -e "print \\\\"\$rep_list_str\\\\n\\\\"" > %>
);
_EOF_

$test->run('chdir' => 'work', flags => "-R $workpath_repository_4 -R $workpath_repository_1 -R $workpath_repository_3 TEST=3", targets => ".");
$test->file_matches($work_replist_3_out, <<_EOF_);
\Q$workpath_repository_4\E
\Q$workpath_repository_1\E
\Q$workpath_repository_3\E
_EOF_

$test->run('chdir' => 'work', flags => "TEST=4", targets => ".");
$test->file_matches($work_replist_4_out, <<_EOF_);

_EOF_

#
$test->pass;
__END__
