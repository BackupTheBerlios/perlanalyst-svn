package Perl::Analysis::Static::Analysis;

=head1 NAME

Perl::Analysis::Static::Analysis

=head1 DESCRIPTION

=head1 METHODS

=cut

use strict;
use warnings;

use base qw(Exporter);

use Carp;

use Perl::Analysis::Static::Log qw(debug message);
use Perl::Analysis::Static::Plugins qw(get_plugins_that_can_analyze);
use Perl::Analysis::Static::File qw(get_all_files);
use Perl::Analysis::Static::PluginList qw(plugin_has_run);
use Perl::Analysis::Static::PluginRanForFile qw(plugin_ran_for_file);

our $VERSION   = 1.000;
our @EXPORT_OK = qw(analyze);

=head1 FUNCTIONS

=head2 analyze

=cut

sub analyze {

	my $plugins = _get_plugins_to_run();

	# get all files from the database
	my $files = get_all_files();

	# FIXME: check

	message("These are the files I'll check:");
	message( $_->path() ) for @$files;

	# sort them
	my @sorted_files = sort { $a->path cmp $b->path } @$files;

	# let all plugins process each file
	for my $file (@sorted_files) {
		for my $plugin (@$plugins) {
			_analyze_file( $file, $plugin );
			
			debug(" (registering in plugin ran for file)");
			plugin_ran_for_file($plugin, $file);
		}
	}

	return 1;
}

=head1 INTERNAL FUNCTIONS

=head2 _analyze_file ($file, $plugin)

=cut

sub _analyze_file {
	my ( $file, $plugin ) = @_;

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

	unless ( $plugin->new->process_file( $document, $file->hex_id ) ) {
		message('error');
		return;
	}

	return 1;
}

=head2 _get_plugins_to_run ()

Gets a list of plugins to run. A plugin has to be run if it is able to analyze and if
it hasn't been run already. 

Returns reference to list of plugins.

=cut

sub _get_plugins_to_run {
	my @result;

	for my $plugin ( get_plugins_that_can_analyze() ) {
		if ( plugin_has_run($plugin) ) {
			message("Plugin '"
				  . $plugin->pretty_name()
				  . "' has run, skipping it" );
			next;
		}
		message("Plugin '$plugin' hasn't run, running it");
		push @result, $plugin;
	}

	return \@result;
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

