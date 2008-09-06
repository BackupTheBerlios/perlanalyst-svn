package Perl::Analysis::Static::PluginRanForFile;

=head1 NAME

Perl::Analysis::Static::PluginRanForFile -- plugin ran for file successfully

=head1 SYNOPSIS

=head1 DESCRIPTION

A row in this table says "The plugin P ran successfully for file F".

=head1 METHODS

=cut

use strict;
use warnings;

use base qw(Exporter Perl::Analysis::Static::DBI);

use Carp;

use Perl::Analysis::Static::Log qw(debug message);
use Perl::Analysis::Static::Database qw(table_exists create_table);

our $VERSION = 1.000;
our @EXPORT_OK=qw(plugin_ran_for_file command_list_plugin_runs);

our $table;

sub _create_instance {
	return $table if $table;

	$table = Perl::Analysis::Static::Table->new(
		name        => 'pluginranforfile',
		columns     => [qw(name file)],
		primary_key => [qw(name file)]
	);
	die "error setting up table 'pluginranforfile'" unless $table;
}


sub plugin_ran_for_file {
	my ( $name, $file ) = @_;

    _create_instance();
    
	# Get the current record, if it exists
	my $plugin = __PACKAGE__->search(name => $name, file => $file);

	if ($plugin) {

		# Update the record to the new values
		message("Updating '$name'");
		$plugin->name($name);
		$plugin->file($file);
		$plugin->update();
	}
	else {

		# Create a new record
		message("Inserting '$name'");
		$plugin = __PACKAGE__->insert( { name => $name, file => $file } );
	}

	return 1;
}

=head2 command_list_plugin_runs ()

not finished yet

=cut

sub command_list_plugin_runs {
	_create_instance();

	$table->select({order_by => 'name, file'});

	my $row = $table->get_next_row();

	unless ($row) {
		print "Not a single plugin ran on any file\n";
	}
	
	while ($row) {
		print "Plugin ".$row->{name}. " ran for file ", $row->{file} . "\n";
		$row = $table->get_next_row();
	}
	
}

1;

=head1 AUTHOR

Gregor Goldbach E<lt>ggoldbach AT cpan DOT orgE<gt>

=head1 SEE ALSO

L<Perl::Analysis::Static::Analysis>, L<PPI>

=head1 COPYRIGHT

Copyright 2008 Gregor Goldbach. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

