package Perl::Analysis::Static::File;

=head1 NAME

Perl::Analysis::Static:::File - A local file to analyze

=head1 DESCRIPTION

This class provides objects that link files on the local filesystem to
the main analysis table via their document C<hex_id>.

=head1 METHODS

In addition to the general methods provided by L<Class::DBI>, this class has
the following additional methods.

=cut

use strict;
use warnings;

use base qw(Perl::Analysis::Static::DBI Exporter);

use Carp;
use PPI::Document;

use Perl::Analysis::Static::Log qw(message debug);

use Digest::MD5 qw(md5_hex);
use File::Spec;
use File::Find::Rule;
use constant FFR => 'File::Find::Rule';

our $VERSION = 1.000;
our @EXPORT_OK = qw(add_directory get_all_files);

=head1 METHODS

=head2 path

The C<path> accessor returns a string which contains the non-relative file
path on the local system.

=head2 checked

The C<checked> accessor returns the Unix epoch time for when the C<hex_id>
was last checked for this file.

=head2 hex_id

In the L<Perl::Analysis::Static> system all documents are identified by the
hexidecimal MD5 value for their contents.

The C<hex_id> accessor returns this id for the file.

=cut

Perl::Analysis::Static::File->table( 'files' );
Perl::Analysis::Static::File->columns( Essential =>
	'path',    # Absolute local filesystem path - '/foo/bar/baz.pm'
	'checked', # UNIX epoch time last checked   - '1128495103'
	'hex_id',  # Document MD5 Identifier        - 'abcdef1234567890'
	);

# Add custom deletion cascade
Perl::Analysis::Static::File->add_trigger(
	before_delete => sub { $_[0]->before_delete },
	);
	
sub before_delete {
	my $self = shift;

	if ( $self->search( hex_id => $self->hex_id )->count == 1 ) {
		# We are the last file with this hex_id.
		# Remove any analysis that were accumulated.
		warn 'DELETE: TODO';
	}

	return 1;
}

# FIXME: use configuration file
# Perl file searcher:
# Find all files ending in pm, pl or t
# not beginning with dots
# ending in cgi
# having perl shebang
my $FIND_PERL = FFR->file->or( FFR->name(qr/\.(?:pm|pl|t)$/i),
	FFR->name( qr/^[^\.]$/, qr/\.cgi/ )
		->grep( qr/^#!.*\bperl/, [ sub {1} ] ) );

=head1 FUNCTIONS

=head2 add_file ($path)

Creates an entry in the C<files> table for a file, referencing the file
name to its C<hex_id>. If the file is relative it will be converted to
it's absolute path first.

=cut

sub add_file {
	my ($path) = @_;

	# check argument
	unless ( $path ) {
		croak("Argument error: need file name");
	}

	# FIXME: use rel2abs()
	unless ( File::Spec->file_name_is_absolute($path) ) {
                my $abspath=File::Spec->rel2abs($path);
                message("Converted '$path' to absolute path '$abspath'");
                $path=$abspath;
	}
	
	croak("File '$path' does not exist") unless -f $path;

	croak("File '$path' doesn't have read permission") unless -r _;
	
	return _add_file($path);
}


=head2 add_directory ($path)

Find files in the directory and add them to the table.

=cut

sub add_directory {

	# Get and check the directory name
	my $path = shift;
	unless ( $path  ) {
		croak("Argument error: need directory name");
	}
	
	unless ( File::Spec->file_name_is_absolute($path) ) {
		my $abspath=File::Spec->rel2abs($path);
		message("Converted '$path' to absolute path '$abspath'");
		$path=$abspath;
	}
	croak("Cannot index '$path'. Directory does not exist")
		unless -d $path;

	croak("Cannot index '$path'. No read permissions")
		unless -r _;

	croak("Cannot index '$path'. No enter permissions")
		unless -x _;

	# Search for all the applicable files in the directory
	message("Search for files in $path");
	
	# FIXME: take file type from configuration or command line
	my @files = $FIND_PERL->in($path);
	message( "Found " . scalar(@files) . " file(s)" );

	# Sort the files so we index in deterministic order
	message("Sorting files");
	@files = sort @files;

	# Index the files
	message("Adding files");
	for my $file (@files) {
		_add_file($file);
	}

	return 1;
}

=head2 get_all_files

Gets all files from the database. It is guaranteed that in the list
are no two files with the same hex_id. Since the hex_id is a MD5-sum
over the contents of the files this means that no two files in the list
have the same contents.

=cut

sub get_all_files {
	my @files = __PACKAGE__->retrieve_all();

	# return if there are no files
	unless (@files ) {
		message("There are no files in the database");
		return;
	}

	message("These are the files found:");
	message( $_->path() ) for @files;

	# reduce list so that files that are equal are checked only once.
	# FIXME: this is a task for the database...

	# hash file by their hex_id (MD5 sum). that way we check
	# files with the same contents (e.g. blib/lib copies)
	# only once.
	my %filehash;
	for my $file (@files) {

		# print a notice that the files are the same
		
		# FIXME: get_all_files() ought to do this 
		if ( exists( $filehash{ $file->hex_id() } ) ) {
			my $other_file = $filehash{ $file->hex_id() }->path();
			message(  $file->path()
					. "has the same contents as "
					. $other_file
					. ", ignoring it" );
		}

		$filehash{ $file->hex_id() } = $file;
	}

	my @hashed_files;
	push @hashed_files, $filehash{$_} for keys %filehash;
	
	return \@hashed_files;
}

=head1 INTERNAL FUNCTIONS

=cut

sub _add_file {
	my ($path)=@_;
			
	my @stats = stat($path);
	# FIXME: check for success

	# Get the current record, if it exists
	my $file = __PACKAGE__->retrieve($path);

	# If we already have a record, and it's checked time
	# is higher than the mtime of the file, the existing
	# hex_id is current and we can shortcut.
	if ( $file and $file->checked > $stats[9] ) {
		message('unchanged');
		return $file;
	}

	# At this point we know we'll need to go to the expense of
	# generating the MD5hex value.
	my $md5hex = _md5($path)
		or croak("Unable to generate hex_id of file '$path'");

	if ($file) {

		# Update the record to the new values
		message("Updating '$path'");
		$file->checked(time);
		$file->hex_id($md5hex);
		$file->update();
	} else {

		# Create a new record
		message("Inserting '$path'");
		$file = __PACKAGE__->insert(
			{   path    => $path,
				checked => time,
				hex_id  => $md5hex,
			}
		);
	}

	return $file;
}

# a simple _slurp implementation
# returns *reference* of string to save memory and be quicker
sub _slurp {
	my ($file) = @_;
	local $/ = undef;

	return unless open( my $fh, '<', $file );
	my $source = <$fh>;
	return unless close($fh);
	return \$source;
}

# calculate MD5 of file's contents
sub _md5 {
	my ($file) = @_;

	my $contents = _slurp($file);
	return unless $contents;

	return md5_hex($$contents);
}
1;

=head1 AUTHOR

Gregor Goldbach E<lt>ggoldbach AT cpan DOT org<gt>

=head1 SEE ALSO

L<Perl::Analysis::Static>, L<PPI>

=head1 COPYRIGHT

Copyright 2008 Gregor Goldbach. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
