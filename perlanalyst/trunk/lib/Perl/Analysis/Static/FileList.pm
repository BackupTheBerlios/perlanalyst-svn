package Perl::Analysis::Static::FileList;

=head1 NAME

Perl::Analysis::Static::FileList

=head1 DESCRIPTION

=head1 METHODS

=cut

use strict;
use warnings;

use Perl::Analysis::Static::Log qw(message);
use Perl::Analysis::Static::Plugins qw(get_plugins_that_can_analyze);
use Perl::Analysis::Static::File;

use base qw(Exporter);

use Carp;
use File::Spec;
use File::Find::Rule;
use constant FFR => 'File::Find::Rule';

use Digest::MD5 qw(md5_hex);

use PPI::Util ();

our $VERSION=1.000;
our @EXPORT_OK=qw(analyze_directory analyze_file);

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

=head2 analyze_directory ($absolute_path)

=cut

sub analyze_directory {
	my ( $directory ) = @_;

	_index_directory($directory);
	_analyze_index();
}

=head2 analyze_file ($absolute_path)

=cut

sub analyze_file {
	my ( $file ) = @_;

	my $f=_index_file($file);
	_analyze_file($f);
}

=head1 INTERNAL FUNCTIONS

=head2 _index_file ($absolute_path)

The C<index_file> method takes a single absolute file path and creates
an entry in the C<files> index, referencing the file name to its
C<hex_id> for later use.

Note that this does not execute any Analysis on the file, merely allows
the system to "remember" the file for later.

=cut

sub _index_file {
	my ($path) = @_;

	# check the filename
	unless ( defined $path and !ref $path and $path ne '' ) {
		croak("Did not pass a file name to index_file");
	}
	
	# FIXME: use rel2abs()
	unless ( File::Spec->file_name_is_absolute($path) ) {
		croak("Cannot index relative path '$path'. Must be absolute");
	}
	croak("Cannot index '$path'. File does not exist")
		unless -f $path;

	croak("Cannot index '$path'. No read permissions")
		unless -r _;
	my @f = stat(_);

	message("Indexing $path");

	# Get the current record, if it exists
	my $file = Perl::Analysis::Static::File->retrieve($path);

	# If we already have a record, and it's checked time
	# is higher than the mtime of the file, the existing
	# hex_id is current and we can shortcut.
	if ( $file and $file->checked > $f[9] ) {
		message('unchanged');
		return $file;
	}

	# At this point we know we'll need to go to the expense of
	# generating the MD5hex value.
	my $md5hex = _md5($path)
		or croak("Cannot index '$path'. Failed to generate hex_id");

	if ($file) {
		# Update the record to the new values
		message('updating');
		$file->checked(time);
		$file->hex_id($md5hex);
		$file->update();
	} else {
		# Create a new record
		message('inserting');
		$file = Perl::Analysis::Static::File->insert(
			{   path    => $path,
				checked => time,
				hex_id  => $md5hex,
			}
		);
	}

	return $file;
}

=head2 _analyze_file ($file)

=cut

sub _analyze_file {
	my ($file) = @_;

	# Has the file been removed since the last run?
	unless ( -f $file->path() ) {

		# Delete the file entry
		$file->delete();
		return 1;
	}

	# get PPI::Document
	my $document = $file->Document();
	return unless $document;

	message("Processing '$file'");
	for my $plugin ( get_plugins_that_can_analyze() ) {
		if ( $plugin->new->process_file( $document, $file->hex_id ) ) {
			#message('done');
		} else {
			message('error');
		}
	}
}

=head2 _index_directory ($absolute_path)

As for C<index_file>, the C<index_directory> method will
recursively scan down a directory tree, locating all Perl files
and adding them to the file index.

Returns the number of files added.

=cut

sub _index_directory {

	# Get and check the directory name
	my $path = shift;
	unless ( defined $path and !ref $path and $path ne '' ) {
		croak("Did not pass a directory name to index_directory");
	}
	unless ( File::Spec->file_name_is_absolute($path) ) {
		croak("Cannot index relative path '$path'. Must be absolute");
	}
	croak("Cannot index '$path'. Directory does not exist")
		unless -d $path;

	croak("Cannot index '$path'. No read permissions")
		unless -r _;

	croak("Cannot index '$path'. No enter permissions")
		unless -x _;

	# Search for all the applicable files in the directory
	message("Search for files in $path");
	my @files = $FIND_PERL->in($path);
	message( "Found " . scalar(@files) . " file(s)" );

	# Sort the files so we index in deterministic order
	message("Sorting files");
	@files = sort @files;

	# Index the files
	message("Indexing files");
	for my $file (@files) {
		_index_file($file);
	}

	return scalar(@files);
}

=head2 _analyze_index

=cut

sub _analyze_index {

	# get all files from the database
	my @files = Perl::Analysis::Static::File->retrieve_all();

	message("These are the files found:");
	message($_->path()) for @files;
	
	# hash file by their hex_id (MD5 sum). that way we check
	# files with the same contents (e.g. blib/lib copies)
	# only once.
	my %filehash;
	for my $file (@files) {
		# print a notice that the files are the same
		if (exists($filehash{$file->hex_id()})) {
			my $other_file=$filehash{$file->hex_id()}->path();
			message($file->path()."has the same contents as "
			.$other_file.", ignoring it");
		}
		
		$filehash{$file->hex_id()}=$file;
	}
	
	my @hashed_files;
	push @hashed_files, $filehash{$_} for keys %filehash;
	
	message("These are the files I'll check:");
	message($_->path()) for @hashed_files;
	
	# sort them
	my @sorted_files = sort { $a->path cmp $b->path } @hashed_files;

	# let all plugins process each file
	for my $file (@sorted_files) {
		_analyze_file($file);
	}

	return 1;
}

# a simple _slurp implementation
# returns *reference* of string to save memory and be quicker
sub _slurp {
        my ($file)=@_;
        local $/ = undef;

        return unless open( my $fh, '<', $file );
        my $source = <$fh>;
        return unless close( $fh );
        return \$source;
}

# calculate MD5 of file's contents
sub _md5 {
	my ($file)=@_;
	
	my $contents=_slurp($file);
	return unless $contents;
	
	return md5_hex($$contents);
}


=head1 AUTHOR

Gregor Goldbach E<lt>ggoldbach AT cpan DOT org<gt>

=head1 COPYRIGHT

Copyright 2008 Gregor Goldbach. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

