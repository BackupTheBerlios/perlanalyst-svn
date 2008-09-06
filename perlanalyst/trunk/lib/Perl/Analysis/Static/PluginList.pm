package Perl::Analysis::Static::PluginList;

=head1 NAME

Perl::Analysis::Static::PluginList - List of plugins that performed analyses

=head1 SYNOPSIS

=head1 DESCRIPTION

The L<Perl::Analysis::Static> system runs its analyses via plugins. Each plugin registers
itself with this list so others get to know quickly what plugins wrote their data to the database.

=head1 METHODS

=cut

use strict;
use warnings;

use base qw(Exporter Perl::Analysis::Static::DBI);

use Carp;

use Perl::Analysis::Static::Log qw(debug message);
use Perl::Analysis::Static::Table;

our $VERSION   = 1.000;
our @EXPORT_OK = qw(command_list_plugins plugin_has_run);

our $table;

sub _create_instance {
	return $table if $table;

	$table = Perl::Analysis::Static::Table->new(
		name        => 'pluginlist',
		columns     => [qw(name version)],
		primary_key => 'name'
	);
	die "error setting up table 'pluginlist'" unless $table;
}

sub register_plugin {
	my ( $name, $version ) = @_;

	_create_instance();

	# this ought to be a method row_exists() (tests for primary key)
	$table->select({where => "name = '$name'"});
	
	# Get the current record, if it exists
	my $plugin = __PACKAGE__->retrieve($name);

	if ($plugin) {

		# Update the record to the new values
		message("Updating '$name'");
		$plugin->name($name);
		$plugin->version($version);
		$plugin->update();
	}
	else {

		# Create a new record
		message("Inserting '$name'");
		$plugin = __PACKAGE__->insert( { name => $name, version => $version } );
	}

	return 1;
}

=head2 command_list_plugins ()

=cut

sub command_list_plugins {
	_create_instance();

	$table->select({order_by => 'name'});

	my $row = $table->get_next_row();
	while ($row) {
		print $row->{name}, ", version ", $row->{version} . "\n";
		$row = $table->get_next_row();
	}

}

=head2 plugin_has_run ($plugi)

Returns 1 if a plugin has been run.

=cut

# TODO: optimize
sub plugin_has_run {
	my ($plugin) = @_;

	# the pretty name is stored in the table
	my $name = $plugin->pretty_name();

	debug("ckecking if plugin '$name' has run");
	my $plugins = get_plugins();

	for my $plugin (@$plugins) {
		return 1 if $plugin->name() eq $name;
	}

	return;
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

