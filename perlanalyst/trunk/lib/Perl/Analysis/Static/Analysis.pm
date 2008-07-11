package Perl::Analysis::Static::Analysis;

=head1 NAME

Perl::Analysis::Static::Analysis

=head1 DESCRIPTION

=head1 METHODS

=cut

use strict;
use warnings;

use Perl::Analysis::Static::Log qw(message);
use Perl::Analysis::Static::Plugins qw(get_plugins_that_can_analyze);
use Perl::Analysis::Static::File qw(get_all_files);

use base qw(Exporter);

use Carp;

our $VERSION   = 1.000;
our @EXPORT_OK = qw(analyze);


=head1 FUNCTIONS

=head2 analyze

=cut

sub analyze {

	# get all files from the database
	my $files=get_all_files();
	# FIXME: check

	message("These are the files I'll check:");
	message( $_->path() ) for @$files;

	# sort them
	my @sorted_files = sort { $a->path cmp $b->path } @$files;

	# let all plugins process each file
	for my $file (@sorted_files) {
		_analyze_file($file);
	}

	return 1;
}


=head2 analyze_file ($file)

=cut

sub analyze_file {
	my ($file) = @_;

	unless ($file) {
		croak "Argument error: need file name";
	}

	_analyze_file($file);
}

=head1 INTERNAL FUNCTIONS

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
	my $path     = $file->path();
	my $document = PPI::Document->new($path);    
	unless ($document) {
		croak("failed to load Perl document '$path'");
	}

	# get plugins that can analyze and run these for the document
	message("Processing '$file'");
	for my $plugin ( get_plugins_that_can_analyze() ) {
		unless ( $plugin->new->process_file( $document, $file->hex_id ) ) {
			message('error');
		}
	}
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

