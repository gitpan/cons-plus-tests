# Copyright 1999-2000 Steven Knight.  All rights reserved.  This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.
#
# This package tests an executable program or script,
# managing one or more temporary working directories,
# keeping track of standard and error output,
# and cleaning up after everything is done.

package Test::Cmd;

use strict;
use vars qw($VERSION @ISA);
use Cwd;
use File::Basename ();	# don't import the basename() method, we redefine it
use File::Find;
use File::Spec;

$VERSION = '1.00';
@ISA = qw(File::Spec);



=head1 NAME

Test::Cmd - Perl module for portable testing of commands and scripts

=head1 SYNOPSIS

  use Test::Cmd;

  $test = Test::Cmd->new(prog => 'program_or_script_to_test',
			interpreter => 'script_interpreter',
			string => 'identifier_string',
			workdir => '',
			subdir => 'dir',
			verbose => 1);

  $test->verbose(1);

  $test->prog('program_or_script_to_test');

  $test->basename(@suffixlist);

  $test->interpreter('script_interpreter');

  $test->string('identifier string');

  $test->workdir('prefix');

  $test->workpath('subdir', 'file');

  $test->subdir('subdir', ...);
  $test->subdir(['sub', 'dir'], ...);

  $test->write('file', <<'EOF');
  contents of file
  EOF
  $test->write(['subdir', 'file'], <<'EOF');
  contents of file
  EOF

  $test->read(\$contents, 'file');
  $test->read(\@lines, 'file');
  $test->read(\$contents, ['subdir', 'file']);
  $test->read(\@lines, ['subdir', 'file']);

  $test->writable('dir', rwflag);

  $test->preserve(condition, ...);

  $test->cleanup(condition);

  $test->run(prog => 'program_or_script_to_test',
		interpreter => 'script_interpreter',
		chdir => 'dir', args => 'arguments', stdin => <<'EOF');
  input to program
  EOF

  $test->pass(condition);
  $test->pass(condition, funcref);

  $test->fail(condition);
  $test->fail(condition, funcref);
  $test->fail(condition, funcref, caller);

  $test->no_result(condition);
  $test->no_result(condition, funcref);
  $test->no_result(condition, funcref, caller);

  $test->stdout;
  $test->stdout(run_number);

  $test->stderr;
  $test->stderr(run_number);

  $test->diff();

  $test->match(\@lines, \@regexes);
  $test->match($lines, $regexes);

  $test->here;

=head1 DESCRIPTION

The C<Test::Cmd> module provides a framework for portable automated
testing of executable commands and scripts (in any language, not
just Perl), especially commands and scripts that require file system
interaction.

In addition to running tests and evaluating conditions, the C<Test::Cmd>
module manages and cleans up one or more temporary workspace directories,
and provides methods for creating files and directories in those workspace
directories from in-line data (that is, here-documents), allowing tests
to be completely self-contained.

The C<Test::Cmd> module inherits File::Spec methods
(C<file_name_is_absolute()>, C<catfile()>, etc.) to support writing
tests portably across a variety of operating and file systems.

A C<Test::Cmd> environment object is created via the usual invocation:

    $test = Test::Cmd->new();

Arguments to the C<Test::Cmd::new> method are keyword-value pairs that
may be used to initialize the object, typically by invoking the same-named
method as the keyword.

No C<Test::Cmd> methods (including the C<new()> method) exit, die
or throw any other sorts of exceptions (but they all do return useful
error indications).  Exceptions should be handled by the test itself or
a subclass specific to the program under test.

The C<Test::Cmd> module may be used in conjunction with the C<Test> module
to report test results in a format suitable for the C<Test::Harness>
module.  A typical use would be to call the C<Test::Cmd> methods to
prepare and execute the test, and call the C<ok()> method exported by the
C<Test> module to test the conditions:

    use Test;
    use Test::Cmd;
    BEGIN { $| = 1; plan => 3 }
    $test = Test::Cmd->new(prog => 'test_program', workdir => '');
    ok($test);
    $wrote_file = $test->write('input_file', <<'EOF');
    This is input to test_program,
    which we expect to process this
    and exit successfully (status 0).
    EOF
    ok($wrote_file);
    $test->run(args => 'input_file');
    ok($? == 0);

Alternatively, the C<Test::Cmd> module provides C<pass()>, C<fail()>,
and C<no_result()> methods that report test results for use with the Aegis
change management system.  These methods terminate the test immediately,
reporting PASSED, FAILED, or NO RESULT respectively, and exiting with
status 0 (success), 1 or 2 respectively.  This allows for a distinction
between an actual failed test and a test that could not be properly
evaluated because of an external condition (such as a full file system
or incorrect permissions):

    use Test::Cmd;
    $test = Test::Cmd->new(prog => 'test_program', workdir => '');
    Test::Cmd->no_result(! $test);
    $wrote_file = $test->write('input_file', <<'EOF');
    This is input to test_program,
    which we expect to process this
    and exit successfully (status 0).
    EOF
    $test->no_result(! $wrote_file);
    $test->run(args => 'input_file');
    $test->fail($? != 0);
    $test->pass;

It is not a good idea to intermix the two reporting models.  If you use
the C<Test> module and its C<ok> method, do not use the C<Test::Cmd>
C<pass>, C<fail> or C<no_result> methods, and vice versa.

=head1 METHODS

Methods supported by the C<Test::Cmd> module include:

=over 4

=cut



my @Cleanup;
my $Run_Count;
my $Default;

# Map exit values to conditions.
my @Cond = ( 'pass', 'fail', 'no_result' );

BEGIN {
    $Run_Count = 0;

    # The File::Spec->tmpdir method was only added recently,
    # so we can't assume it's there.
    $Test::Cmd::TMPDIR = eval("File::Spec->tmpdir");

    # now we do win32 detection. what a mess :-(
    # if the version is 5.003, we can check $^O
    my $iswin32;
    if ($] <  5.003) {
	eval("require Win32");
	$iswin32 = ! $@;
    } else {
	$iswin32 = $^O eq "MSWin32";
    }

    if ($iswin32) {
	eval("use Win32;");
	$Test::Cmd::_WIN32 = 1;
	$Test::Cmd::Temp_Prefix = "~testcmd$$-";
	$Test::Cmd::Cwd_Ref = \&Win32::GetCwd;
	if (! $Test::Cmd::TMPDIR) {
	    # Test for WIN32 temporary directories.
	    # The following is lifted from the 5.005056
	    # version of File::Spec::Win32::tmpdir.
	    foreach (@ENV{qw(TMPDIR TEMP TMP)}, qw(/tmp /)) {
		next unless defined && -d;
		$Test::Cmd::TMPDIR = $_;
		last;
	    }
	}
    } else {
	$Test::Cmd::Temp_Prefix = "testcmd$$.";
	$Test::Cmd::Cwd_Ref = \&Cwd::cwd;
	if (! $Test::Cmd::TMPDIR) {
	    # Test for UNIX temporary directories.
	    # The following is lifted from the 5.005056
	    # version of File::Spec::Unix::tmpdir.
	    foreach ($ENV{TMPDIR}, "/tmp") {
		next unless defined && -d && -w _;
		$Test::Cmd::TMPDIR = $_;
		last;
	    }
	}
    }

    $Default = {};

    $Default->{'failed'} = 0;
    $Default->{'verbose'} = $ENV{VERBOSE} || 0;

    if (defined $ENV{PRESERVE}) {
	$Default->{'preserve'}->{'fail'} = $ENV{PRESERVE} || 0;
	$Default->{'preserve'}->{'pass'} = $ENV{PRESERVE} || 0;
	$Default->{'preserve'}->{'no_result'} = $ENV{PRESERVE} || 0;
    } else {
	$Default->{'preserve'}->{'fail'} = $ENV{PRESERVE_FAIL} || 0;
	$Default->{'preserve'}->{'pass'} = $ENV{PRESERVE_PASS} || 0;
	$Default->{'preserve'}->{'no_result'} = $ENV{PRESERVE_NO_RESULT} || 0;
    }

    sub handler {
	print STDERR "NO RESULT -- SIG$_ received.\n";
	my $test;
	foreach $test (@Cleanup) {
	    $test->cleanup('no_result');
	}
	exit(2);
    }

    $SIG{HUP} = \&handler if $SIG{HUP};
    $SIG{INT} = \&handler;
    $SIG{QUIT} = \&handler;
    $SIG{TERM} = \&handler;
}

END {
    my $cond = @Cond[$?] || 'no_result';
    my $test;
    foreach $test (@Cleanup) {
	$test->cleanup($cond);
    }
}



=item C<new>

Create a new C<Test::Cmd> environment.  Arguments with which to initialize
the environment are passed in as keyword-value pairs.  Fails if a
specified temporary working directory or subdirectory cannot be created.
Does NOT die or exit on failure, but returns FALSE if the test environment
object cannot be created.

=cut

sub new {
    my $type = shift;
    my $self = {};

    %$self = %$Default;

    $self->{'cleanup'} = [];

    $self->{'preserve'} = {};
    %{$self->{'preserve'}} = %{$Default->{'preserve'}};

    $self->{'cwd'} = cwd();

    while (@_) {
	my $keyword = shift;
	$self->{$keyword} = shift;
    }

    bless $self, $type;

    if (defined $self->{'workdir'}) {
	if (! $self->workdir($self->{'workdir'})) {
	    return undef;
	}
    }
    if (defined $self->{'subdir'}) {
	if (! $self->subdir($self->{'subdir'})) {
	    return undef;
	}
    }

    $self->prog($self->{'prog'});

    push @Cleanup, $self;

    $self;
}



=item C<verbose>

Sets the verbose level for the environment object to the specified value.

=cut

sub verbose {
    my $self = shift;
    $self->{'verbose'} = $_;
}



=item C<prog>

Specifies the executable program or script to be tested.  Returns the
absolute path name of the current program or script.

=cut

sub prog {
    my ($self, $prog) = @_;
    if ($prog) {
	# make sure we're always talking about the same program
	if (! $self->file_name_is_absolute($prog)) {
	    $prog = $self->catfile($self->{'cwd'}, $prog);
	}
	$self->{'prog'} = $prog;
    }
    return $self->{'prog'};
}



=item C<basename>

Returns the basename of the current program or script.  Any specified
arguments are a list of file suffixes that may be stripped from the
basename.

=cut

sub basename {
    my $self = shift;
    return undef if ! $self->{'prog'};
    File::Basename::basename($self->{'prog'}, @_);
}



=item C<interpreter>

Specifies the program to be used to interpret C<prog> as a script.
Returns the current value of C<interpreter>.

=cut

sub interpreter {
    my ($self, $interpreter) = @_;
    $self->{'interpreter'} = $interpreter if $interpreter;
    $self->{'interpreter'};
}



=item C<string>

Specifies an identifier string for the functionality being tested to be
printed on failure or no result.

=cut

sub string {
    my ($self, $string) = @_;
    $self->{'string'} = $string if $string;
    $self->{'string'};
}



my $counter = 0;

sub _workdir_name {
    my $self = shift;
    while (1) {
	 $counter++;
	 my $name = $self->catfile($Test::Cmd::TMPDIR,
					$Test::Cmd::Temp_Prefix . $counter);
	 return $name if ! -e $name;
    }
}

=item C<workdir>

When an argument is specified, creates a temporary working directory
with the specified name.  If the argument is a NULL string (''),
the directory is named C<testcmd> by default, followed by the
unique ID of the executing process.

Returns the absolute pathname to the temporary working directory, or
FALSE if the directory could not be created.

=cut

sub workdir {
    my ($self, $workdir) = @_;
    if (defined($workdir)) {
#	return if $workdir && $self->{'workdir'} eq $workdir;	# no change
	my $wdir = $workdir || $self->_workdir_name;
	if (!mkdir($wdir, 0755)) {
	    return undef;
	}
	$self->{'workdir'} = $wdir;
	push(@{$self->{'cleanup'}}, $self->{'workdir'});
    }
    $self->{'workdir'};
}



=item C<workpath>

Returns the absolute path name to a subdirectory or file under the
current temporary working directory by concatenating the temporary
working directory name with the specified arguments.

=cut

sub workpath {
    my $self = shift;
    return undef if ! $self->{'workdir'};
    $self->catfile($self->{'workdir'}, @_);
}



=item C<subdir>

Creates new subdirectories under the temporary working dir, one for
each argument.  An argument may be an array reference, in which case the
array elements are concatenated together using the C<File::Spec-&>catfile>
method.  Subdirectories multiple levels deep must be created via a
separate argument for each level:

    $test->subdir('sub', ['sub', 'dir'], [qw(sub dir ectory)]);

Returns the number of subdirectories actually created.

=cut

sub subdir {
    my $self = shift;
    my $count = 0;
    foreach (@_) {
	my $newdir = $self->catfile($self->{'workdir'}, ref $_ ? @$_ : $_);
	if (mkdir($newdir, 0755)) {
	    $count++;
	}
    }
    return $count;
}



=item C<write>

Writes the specified text (second argument) to the specified file name
(first argument).  The file name may be an array reference, in which
case all the array elements except the last are subdirectory names
to be concatenated together.  The file is created under the temporary
working directory.  Any subdirectories in the path must already exist.

=cut

sub write {
    my $self = shift;
    my $file = shift; # the file to write to
    if (! $self->file_name_is_absolute($file)) {
	$file = $self->catfile($self->{'workdir'}, ref $file ? @$file : $file);
    }
    if (! open(OUT, ">$file")) {
	return undef;
    }
    if (! print OUT @_) {
	return undef;
    }
    return close(OUT);
}



=item C<read>

Reads the contents of the specified file name (second argument) into
the scalar or array referred to by the first argument.  The file name
may be an array reference, in which case all the array elements except
the last are subdirectory names to be concatenated together.  The file
is assumed to be under the temporary working directory unless it is an
absolute path name.

Returns TRUE on successfully opening and reading the file, FALSE
otherwise.

=cut

sub read {
    my ($self, $destref, $file) = @_;
    return undef if ref $destref ne 'SCALAR' && ref $destref ne 'ARRAY';
    if (! $self->file_name_is_absolute($file)) {
	$file = $self->catfile($self->{'workdir'}, ref $file ? @$file : $file);
    }
    if (! open(IN, "<$file")) {
	return undef;
    }
    my @lines = <IN>;
    if (! close(IN)) {
	return undef;
    }
    if (ref $destref eq 'SCALAR') {
	$$destref = join('', @lines);
    } else {
	@$destref = @lines;
    }
    return (1);
}



=item C<writable>

Makes the specified directory tree writable (C<rwflag> == TRUE) or not
writable (C<rwflag> == FALSE).

=cut

sub _writable {
    if (!chmod 0755, $_) {
	no_result("Unable to change the access mode on '$_': $!\n");
    }
}

sub _writeprotect {
    if (!chmod 0555, $_) {
	no_result("Unable to change the access mode on '$_': $!\n");
    }
}

sub writable {
    my ($self, $dir, $flag) = @_;
    if ($flag) {
	finddepth(\&_writable, $dir);
    } else {
	finddepth(\&_writeprotect, $dir);
    }
}



=item C<preserve>

Arranges for the temporary working directories for the specified
C<Test::Cmd> environment to be preserved for one or more conditions.
If no conditions are specified, arranges for the temporary working
directories to be preserved for all conditions.

=cut

sub preserve {
    my $self = shift;
    my @cond = (@_) ? @_ : qw(pass fail no_result);
    my $cond;
    foreach $cond (@cond) {
	$self->{'preserve'}->{$cond} = 1;
    }
}



sub _nuke {
#    print STDERR "unlink($_)\n" if (!-d $_);
#    print STDERR "rmdir($_)\n" if (-d $_ && $_ ne ".");
    unlink($_) if (!-d $_);
    rmdir($_) if (-d $_ && $_ ne ".");
    1;
}



=item C<cleanup>

Removes any temporary working directories for the specified C<Test::Cmd>
environment.  If the environment variable C<PRESERVE> was set when
the C<Test::Cmd> module was loaded, temporary working directories are
not removed.  If any of the environment variables C<PRESERVE_PASS>,
C<PRESERVE_FAIL>, or C<PRESERVE_NO_RESULT> were set when the C<Test::Cmd>
module was loaded, then temporary working directories are not removed
if the test passed, failed, or had no result, respectively.  Temporary
working directories are also preserved for conditions specified via the
C<preserve> method.

Typically, this method is not called directly, but is used when the
script exits to clean up temporary working directories as appropriate
for the exit status.

=cut

sub cleanup {
    my ($self, $cond) = @_;
    $cond = (($self->{'failed'} == 0) ? 'pass' : 'fail') if !$cond;
    if ($self->{'preserve'}->{$cond}) {
	print STDERR "Preserving work directory ".$self->{'workdir'}."\n" if $self->{'verbose'};
	return;
    }
    chdir $self->{'cwd'}; # cd out of whatever work dir we're in
    my $dir;
    foreach $dir (@{$self->{'cleanup'}}) {
	$self->writable($dir, "true");
	finddepth(\&_nuke, $dir);
	rmdir($dir);
    }
    $self->{'cleanup'} = [];
}



=item C<run>

Runs a test of the program or script for the test environment.  Standard
output and error output are saved for future retrieval via the C<stdout>
and C<stderr> methods.

Arguments are supplied as keyword-value pairs:

=over 4

=item C<args>

Specifies the command-line arguments to be supplied to the program
or script under test for this run:

	$test->run(args => 'arg1 arg2');

=item C<chdir>

Changes directory to the path specified as the value argument:

	$test->run(chdir => 'xyzzy');

If the specified path is not an absolute path name (begins with '/'
on Unix systems), then the subdirectory is relative to the temporary
working directory for the environment (C<$test-&>workdir>).  Note that,
by default, the C<Test::Cmd> module does NOT chdir to the temporary
working directory, so to execute the test under the temporary working
directory, you must specify an explicit C<chdir> to the current directory:

	$test->run(chdir => '.');		# Unix-specific

	$test->run(chdir => $test->curdir);	# portable

=item C<interpreter>

Specifies the program to be used to interpret C<prog> as a script,
for this run only.  This does not change the C<$test-&>interpreter>
value of the test environment.

=item C<prog>

Specifies the executable program or script to be run, for this run only.
This does not change the C<$test-&>prog> value of the test environment.

=item C<stdin>

Pipes the specified value (string or array ref) to the program
or script under test for this run:

	$test->run(stdin => <<_EOF_);
	input to the program under test
	_EOF_

=back

Returns the exit status of the program or script.

=cut

sub run {
    my $self = shift;
    my %args = @_;
    my $oldcwd;
    if ($args{'chdir'}) {
	$oldcwd = Cwd::cwd();
	if (! $self->file_name_is_absolute($args{'chdir'})) {
	    $args{'chdir'} = $self->catfile($self->{'workdir'}, $args{'chdir'});
	}
	print STDERR "Changing to $args{'chdir'}\n" if $self->{'verbose'};
	if (!chdir $args{'chdir'}) {
	    return undef;
	}
    }
    $Run_Count++;
    my $stdout_file = $self->_stdout_file($Run_Count);
    my $stderr_file = $self->_stderr_file($Run_Count);
    my $cmd;
    if ($args{'prog'}) {
	if (! $self->file_name_is_absolute($args{'prog'})) {
	    $args{'prog'} = $self->catfile($self->{'cwd'}, $args{'prog'});
	}
	$cmd = $args{'prog'};
	$cmd = $args{'interpreter'}." ".$cmd if $args{'interpreter'};
    } else {
	$cmd = $self->{'prog'};
	$cmd = $self->{'interpreter'}." ".$cmd if $self->{'interpreter'};
    }
    $cmd = $cmd." ".$args{'args'} if $args{'args'};
    $cmd =~ s/\$work/$self->{'workdir'}/g;
    $cmd = "|$cmd 1>$stdout_file 2>$stderr_file";
    print STDERR "Invoking $cmd\n" if $self->{'verbose'};
    if (! open(RUN, $cmd)) {
	$? = 2;
	print STDERR "Could not invoke $cmd: $!\n";
	return undef;
    }
    if ($args{'stdin'}) {
	print RUN ref $args{'stdin'} ? @{$args{'stdin'}} : $args{'stdin'};
    }
    close(RUN);
    my $return = $?;
    chdir $oldcwd if $oldcwd;
    return $return;
}



sub _to_value {
    my ($v) = @_;
    (ref $v or '') eq 'CODE' ? &$v() : $v;
}



=item C<pass>

Exits the test successfully.  Reports "PASSED" on the error output and
exits with a status of 0.  If a condition is supplied, only exits
the test if the condition evaluates TRUE.  If a function reference is
supplied, executes the function before reporting and exiting.

=cut

sub pass {
    my $self = shift;
    @_ = (1) if @_ == 0; # provide default arg
    my ($cond, $funcref) = @_;
    return if ! _to_value($cond);
    &$funcref() if $funcref;
    print STDERR "PASSED\n";
    # Let END take care of cleanup.
    exit (0);
}



=item C<fail>

Exits the test unsuccessfully.  Reports "FAILED test of {string} at line
{line} of {file}." on the error output and exits with a status of 1.
If a condition is supplied, only exits the test if the condition evaluates
TRUE.  If a function reference is supplied, executes the function before
reporting and exiting.  If a caller level is supplied, prints a simple
calling trace N levels deep as part of reporting the failure.

=cut

sub fail {
    my $self = shift;
    @_ = (1) if @_ == 0; # provide default arg
    my ($cond, $funcref, $caller) = @_;
    return if ! _to_value($cond);
    &$funcref() if $funcref;
    $caller = 0 if ! defined($caller);
    my $of_str = " ";
    if (ref $self) {
	my $basename = $self->basename;
	if ($basename) {
	    $of_str = " of ".$self->basename;
	    if ($self->{'string'}) {
		$of_str .= " [".$self->{'string'}."]";
	    }
	    $of_str .= "\n\t";
	}
    }
    my $c = 0;
    my ($pkg,$file,$line,$sub) = caller($c++);
    print STDERR "FAILED test${of_str}at line $line of $file";
    while ($c <= $caller) {
	    ($pkg,$file,$line,$sub) = caller($c++);
	    print STDERR " ($sub)\n\tfrom line $line of $file";
    }
    print STDERR ".\n";
    # Let END take care of cleanup.
    exit (1);
}



=item C<no_result>

Exits the test with an indeterminate result (the test could not be
performed due to external conditions such as, for example, a full
file system).  Reports "NO RESULT for test of {string} at line {line} of
{file}." on the error output and exits with a status of 2.  If a condition
is supplied, only exits the test if the condition evaluates TRUE.  If a
function reference is supplied, executes the function before reporting
and exiting.  If a caller level is supplied, prints a simple calling
trace N levels deep as part of reporting the failure.

=cut

sub no_result {
    my $self = shift;
    @_ = (1) if @_ == 0; # provide default arg
    my ($cond, $funcref, $caller) = @_;
    return if ! _to_value($cond);
    &$funcref() if $funcref;
    $caller = 0 if ! defined($caller);
    my $of_str = " ";
    if (ref $self) {
	my $basename = $self->basename;
	if ($basename) {
	    $of_str = " of ".$self->basename;
	    if ($self->{'string'}) {
		$of_str .= " [".$self->{'string'}."]";
	    }
	    $of_str .= "\n\t";
	}
    }
    my $c = 0;
    my ($pkg,$file,$line,$sub) = caller($c++);
    print STDERR "NO RESULT for test${of_str}at line $line of $file";
    while ($c <= $caller) {
	    ($pkg,$file,$line,$sub) = caller($c++);
	    print STDERR " ($sub)\n\tfrom line $line of $file";
    }
    print STDERR ".\n";
    # Let END take care of cleanup.
    exit (2);
}



sub _stdout_file {
    my ($self, $count) = @_;
    $self->catfile($self->{'workdir'}, "stdout.$count");
}

sub _stderr_file {
    my ($self, $count) = @_;
    $self->catfile($self->{'workdir'}, "stderr.$count");
}






=item C<stdout>

Returns the standard output from the specified run number.  If there is no
specified run number, then returns the standard output of the last run.
Returns the standard output as either a scalar or an array of output
lines, as appropriate for the calling context.  Returns C<undef> if
there has been no test run.

=cut

sub stdout {
    my $self = shift;
    my $count = @_ ? shift : $Run_Count;
    return undef if ! $Run_Count;
    my @lines;
    if (! $self->read(\@lines, $self->_stdout_file($count))) {
	return undef;
    }
    return (wantarray ? @lines : join('', @lines));
}



=item C<stderr>

Returns the error output from the specified run number.  If there is
no specified run number, then returns the error output of the last run.
Returns the error output as either a scalar or an array of output lines,
as apporpriate for the calling context.  Returns C<undef> if there has
been no test run.

=cut

sub stderr {
    my $self = shift;
    my $count = @_ ? shift : $Run_Count;
    return undef if ! $Run_Count;
    my @lines;
    if (! $self->read(\@lines, $self->_stderr_file($count))) {
	return undef;
    }
    return (wantarray ? @lines : join('', @lines));
}



=item C<diff>

Not Yet Implemented.

=cut

sub diff {
}



=item C<match>

Matches one or more input lines against an equal number of regular
expressions.  The arguments are passed in as either scalars, in which
case each is split on newline boundaries, or as array references.
Trailing newlines are stripped from each line and regular expression.
An unequal number of lines and regular expressions fails immediately
and returns FALSE before any comparisons are performed.  Comparison is
performed for each entire line, that is, with each regular expression
anchored at both the start of line (^) and end of line ($).

Returns TRUE if each line matched each regular expression, FALSE
otherwise.

=cut

sub match {
    my($self, $lines, $regexes) = @_;
    if (! ref $lines) {
	my @line_array = split(/\n/, $lines, -1);
	pop(@line_array);
	$lines = \@line_array;
    }
    if (! ref $regexes) {
	my @regex_array = split(/\n/, $regexes, -1);
	pop(@regex_array);
	$regexes = \@regex_array;
    }
    return undef if @$lines != @$regexes;
    my($i, $re, $l);
    for ($i = 0; $i <= $#{ $regexes }; $i++) {
	chomp($l = $lines->[$i]);
	chomp($re = $regexes->[$i]);
	#if ($l !~ m/^$re$/) {
	#	print STDERR "Line ", $i+1, " does not match:\n";
	#	print STDERR "Expect:  $re\n";
	#	print STDERR "Got:     $l\n";
	#}
	return undef if $l !~ m/^$re$/;
    }
    return 1;
}



=item C<here>

Returns the absolute path name of the current working directory.
(This is essentially the same as the C<Cwd::cwd> method, except that the
C<Test::Cmd::here> method preserves the directory separators exactly
as returned by the underlying operating-system-dependent method.
The C<Cwd::cwd> method canonicalizes all directory separators to '/',
which makes for consistent path name representations within Perl, but may
mess up another program or script to which you try to pass the path name.)

=cut

sub here {
    &$Test::Cmd::Cwd_Ref();
}



1;
__END__

=back

=head1 ENVIRONMENT

Several environment variables affect the default values in a newly created
C<Test::Cmd> environment object.  These environment variables must be set
when the module is loaded, not when the object is created.

=over 4

=item C<PRESERVE>

If set to a true value, all temporary working directories will
be preserved on exit, regardless of success or failure of the test.
The full path names of all temporary working directories will be reported
on error output.

=item C<PRESERVE_FAIL>

If set to a true value, all temporary working directories will be
preserved on exit from a failed test.  The full path names of all
temporary working directories will be reported on error output.

=item C<PRESERVE_NO_RESULT>

If set to a true value, all temporary working directories will be
preserved on exit from a test for which there is no result.  The full
path names of all temporary working directories will be reported on
error output.

=item C<PRESERVE_PASS>

If set to a true value, all temporary working directories will be
preserved on exit from a successful test.  The full path names of all
temporary working directories will be reported on error output.

=item C<VERBOSE>

When set to a true value, enables verbose reporting of various internal
things (path names, exact command line being executed, etc.).

=back

=head1 PORTABLE TESTS

Although the C<Test::Cmd> module is intended to make it easier to write
portable tests for portable utilities that interact with file systems,
it is still very easy to write non-portable tests if you're not careful.

The best and most comprehensive set of portability guidelines is the
standard "Writing portable Perl" document at:

	http://www.perl.com/pub/doc/manual/html/pod/perlport.html

To reiterate one important point from the "WpP" document:  Not all Perl
programs have to be portable.  If the program or script you're testing
is UNIX-specific, you can (and should) use the C<Test::Cmd> module to
write UNIX-specific tests.

That having been said, here are some hints that may help keep your tests
portable, if that's a requirement.

=over 4

=item Use the C<Test::Cmd-&>here> method for current directory path.

The normal Perl way to fetch the current working directory is to use the
C<Cwd::cwd> method.  Unfortunately, the C<Cwd::cwd> method canonicalizes
the path name it returns, changing the native directory separators into
the forward slashes favored by Perl and UNIX.  For most Perl scripts,
this makes a great deal of sense and keeps code uncluttered.

Passing in a file name that has had its directory separators altered,
however, may confuse the command or script under test, or make it
difficult to compare output from the command or script with an expected
result.  The C<Test::Cmd::here> method returns the absolute path name of
the current working directory, like C<Cwd::cwd>, but does not manipulate
the returned path in any way.

=item Use C<File::Spec> methods for manipulating path names.

The C<File::Spec> module provides a system-independent interface for
manipulating path names.  Because the C<Test::Cmd> class is a sub-class
of the C<File::Spec> class, you can use these methods directly as follows:

	if (! Test::Cmd->file_name_is_absolute($prog)) {
		my $prog = Test::Cmd->catfile(Test::Cmd->here, $prog);
	}

For details about the available methods and their use, see the
documentation for the C<File::Spec> module and its sub-modules, especially
the C<File::Spec::Unix> modules.

=item Use C<Config> for file-name suffixes, where possible.

The standard C<Config> module provides values that reflect the file-name
suffixes on the system for which the Perl executable was built.
This provides convenient portability for situations where a file name
may have different extensions on different systems:

	$foo_exe = "foo$Config{_exe}";
	ok(-f $foo_exe);

(Unfortunately, there is no existing C<$Config> value that specifies
the suffix for a directly-executable Perl script.)

=item Avoid generating executable programs or scripts.

How to make a file or script executable varies widely from system to
system, some systems using file name extensions to indicate executability,
others using a file permission bit.  The differences are complicated to
accomodate in a portable test script.  The easiest way to deal with this
complexity is to avoid it if you can.

If your test somehow requires executing a script that you generate
from the test itself, the best way is to generate the script in Perl
and then explicitly feed it to the Perl executable on the local system.
To be maximally portable, use the C<$^X> variable instead of hard-coding
"perl" into the string you execute:

	$line = "This is output from the generated perl script.";
	$test->write('script', <<EOF);
	print STDOUT "$line\\n";
	EOF
	$output = `$^X script`;
	ok($output eq "$line\n");

This completely avoids having to make the C<script> file itself
executable.  (Since you're writing your test in Perl, it's safe to assume
that Perl itself is executable.)

If you must generate a directly-executable script, then use the
C<$Config{'startperl'}> variable at the start of the script to generate
the appropriate magic that will execute it as a Perl script:

	use Config;
	$line = "This is output from the generated perl script.";
	$test->write('script', <<EOF);
	$Config{'startperl'};
	print STDOUT "$line\\n";
	EOF
	chdir($test->workdir);
	chmod(0755, 'script');	# POSIX-SPECIFIC
	$output = `script`;
	ok($output eq "$line\n");

=back 4

Addtional hints on writing portable tests are welcome.

=head1 SEE ALSO

perl(1), File::Find(3), File::Spec(3), Test(3), Test::Harness(3).

A rudimentary page for the Test::Cmd module is available at:

	http://www.baldmt.com/Test-Cmd/

=head1 AUTHORS

Steven Knight, knight@baldmt.com

=head1 COPYRIGHT

Copyright 1999-2000 Steven Knight.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

Thanks to Greg Spencer for the inspiration to create this package and
the initial draft of its implementation as a specific testing package
for the Cons software construction utility.  Information about Cons
is available at:

	http://www.dsmit.com/cons/

The general idea of managing temporary working directories in this way,
as well as the test reporting of the C<pass>, C<fail> and C<no_result>
methods, come from the testing framework invented by Peter Miller for
his Aegis project change supervisor.  Aegis is an excellent bit of work
which integrates creation and execution of regression tests into the
software development process.  Information about Aegis is available at:

	http://www.tip.net.au/~millerp/aegis.html

=cut
