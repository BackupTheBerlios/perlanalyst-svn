package Perl::Analysis::Static::Plugin;

=head1 NAME

Perl::Analysis::Static::Plugin - Base class for Perl::Analysis::Static plugins

=head1 SYNOPSIS

=head1 DESCRIPTION

The L<Perl::Analysis::Static> system does not in and of itself generate any actual
analysis data, it merely acts as a processing and storage engine.

The generation of the actual analysis data is done via plugins,
which are implemented as C<Perl::Analysis::Static::Plugin> sub-classes.

=head2 Implementing Your Own Analysis

Implementing an analysis is pretty easy.

First, create a Perl::Analysis::Static::Plugin::Something package, inheriting
from C<Perl::Analysis::Static::Plugin>.

The create a subroutine analyze. It will be passed the L<PPI::Document> object
to analyze.

Return ...

=head1 METHODS

=cut

use strict;
use warnings;

use base 'Perl::Analysis::Static::DBI';

use Carp;

use Perl::Analysis::Static::Log qw(debug message);
use Perl::Analysis::Static::Database qw(table_exists create_table);
use Perl::Analysis::Static::PluginList;

our $VERSION = 1.000;

our @ESSENTIAL_COLUMNS_PREFIX = qw(hex_id version);

=head2

Set up the table name and the columns upon module import.

Maybe move to constructor?

=cut

sub import {
	my $class = shift;

	# setting table name for class
	$class->table( $class->table_name );

	# setting up columns
	$class->columns( Primary => _get_primary_columns() );

	$class->columns( Essential =>
		  ( @ESSENTIAL_COLUMNS_PREFIX, $class->_get_additional_columns() ) );
}

sub _get_additional_columns { () }

# override for other primary columns
sub _get_primary_columns { ('hex_id') }

=head2 new

Creates a new instance and registers the plugin in the list of plugins.

=cut

sub new {
	my $class = ref $_[0] ? ref shift: shift;
	my $self = bless {}, $class;

	return $self;
}

=head2 files

Get all files with this hex_id.

=cut

sub files {
	my $self = shift;

	# Apply default search options to those passed
	my @params = ( hex_id => $self->hex_id, @_ );
	unless ( ref( $params[-1] ) eq 'HASH' ) {

		# Add standard ordering
		push @params, { order_by => 'file' };
	}

	# Execute the search
	Perl::Analysis::Static::File->search(@params);
}

=head2 class

A convenience method to get the class for the plugin object,
to avoid having to use ref directly (and making the intent of
any code a little clearer).

=cut

sub class { ref $_[0] || $_[0] }

=head2 process_index

The C<process_index> method will cause the metrics plugin to scan every
single file entry in the database, and run any an all metrics required to
bring to the database up to complete coverage for that plugin.

This process may take some time for large indexes.

=cut

sub process_index {
	my $self = shift;

	# get all files
	my @files = Perl::Analysis::Static::File->retrieve_all();

	# sort them
	@files = sort { $a->path cmp $b->path } @files;

	for my $file (@files) {
		message("Processing '$file'");
		if ( $self->process_file($file) ) {
			message("done\n");
		}
		else {
			message("error\n");
		}
	}

	return 1;
}

=head2 process_file ($document, $hex_id)

Run the plugin's analyze method and store the results in the
database.

=cut

sub process_file {
	my ( $self, $document, $hex_id ) = @_;

	unless ( $self->can_analyze() ) {
		message("$self can't analyze");
		return 1;
	}

	#	my $output="$self";
	# remove prefix
	#	$output =~ s{Perl::Analysis::Static::Plugin::}{};
	my $output = $self->pretty_name();
	message(" ($output)");

	debug(" (registering in plugin list)");
    Perl::Analysis::Static::PluginList::register_plugin($self->pretty_name(), $VERSION);

	my $result = $self->analyze($document);

	# returning undef is an error
	unless ( defined $result ) {
		message("   no results");
		return 1;
	}

	my $results;

	if (   ( not ref($result) )
		or ( ref($result) ne 'ARRAY' and ref($result) ne 'HASH' ) )
	{
		die 'Expecting analyze to return reference to array or hash';
	}

	# turn one result into list of results
	if ( ref($result) eq 'HASH' ) {
		$results = [$result];
	}
	else {

		# we already have list of results
		$results = $result;
	}

	# insert list of results
	for my $value (@$results) {
		my $hashref = _extend_insert_hashref( $value, $hex_id );

		if ( $self->pretty_name() eq 'Location::FunctionCall' ) {
			#use Data::Dumper;
			#debug( Dumper($hashref) );
		}
		$self->insert($hashref);
	}

	return 1;
}

sub _extend_insert_hashref {
	my ( $hashref, $hex_id ) = @_;

	$hashref->{hex_id}  = $hex_id;
	$hashref->{version} = $VERSION;

	return $hashref;
}

sub build_create_table_string {
	my ($self) = @_;

	# build table name from class name
	my $table_name = $self->table_name();

	my $line = $self->_build_additional_creation_string();

	my $primary_key = $self->_build_primary_key_string();

	message("creating table '$table_name'");

	return <<"END_SQL";
CREATE TABLE $table_name (
	hex_id  TEXT    NOT NULL,
	version NUMERIC,
	$line PRIMARY KEY ($primary_key)
);
END_SQL

}

sub _build_additional_creation_string {
	my $self = shift;

	# get columns
	my @columns = $self->_get_additional_columns();

	# get types for them
	my @types = $self->_get_additional_columns_types();

	my $line;
	while (@columns) {
		my $column = pop @columns;
		my $type   = pop @types;

		$line .= "$column $type,\n";
	}

	return $line;
}

sub _build_primary_key_string {
	my $self = shift;

	# get columns
	my @columns = $self->_get_primary_columns();

	my $line = join( ',', @columns );

	return $line;
}

=head2 table_name ()

Creates table name based on the class' name.

C<Perl::Analysis::Static::> is removed and double double colons are
replaced with an underscore.

Returns name.

=cut

sub table_name {
	my $self = shift;

	my $name = $self->class();

	# remove Perl::Analysis::Static::Analysis
	$name =~ s{Perl::Analysis::Static::}{};

	# substitute :: with _
	$name =~ s{::}{_}g;

	return $name;
}

=head2 can_analyze

Tells the caller if the plugin actually can analyze.

This is done by checking if the plugin has a method
called 'analyze'. If a plugin doesn't analyze we
don't have to create a table for it.

=cut

sub can_analyze {
	my ($self) = @_;

	# do we have this method?
	return $self->can('analyze');
}

=head2 setup_table

A plugin that can't analyze doesn't need a table to store
the data in, so we first check if the plugin is able to analyze.
This method returns immediately 1 if the plugin can analyze.

It creates the table if it doesn't exist so the plugin may safely
store the data it collects.

If the table exists it has to be cleared. If we don't do this we
might get duplicate records and/or have data from old versions of
the plugin.

After calling this method the caller can be assured that there's
an empty table for this plugin.

Returns 1 on success, undef on error.

=cut

sub setup_table {
	my ($self) = @_;

	# we don't need the table if we can't analyze
	unless ( $self->can_analyze() ) {
		message("Plugin '$self' can't analyze, won't create table");
		return 1;
	}

	# we create the table if it doesn't exist
	unless ( table_exists( $self->table_name() ) ) {
		message("creating table for plugin '$self'");
		return create_table($self);
	}

	# delete all entries if the table exists
	message("table exists for plugin '$self', deleting all entries");

	# TODO: check if plugin has a greater version.
	# if not, we don't
	# need to re-run it since the data it would collect
	# is already there (so deleting wouldn't be neccessary).

	my $all   = $self->retrieve_all();
	my $count = $all->count();
	message("Removing $count entries");
	$all->delete_all();
	message('table is empty now');

	return 1;
}

sub pretty_name {
	my ($self) = @_;

	my $result = $self->class();

	# remove prefix
	$result =~ s{Perl::Analysis::Static::Plugin::}{};

	return $result;
}

=head2 rows_for_file ($hex_id)

Get all rows for the file with this hex_id.

Returns undef if there are no rows, reference to list of rows otherwise.

The rows are not ordered.

Override this for plugins that have other columns as primary key (e.g. the
Location plugin: see L<Perl::Analysis::Static::Plugin::Location>).

=cut

sub rows_for_file {
	my ($self, $hex_id)=@_;

	croak "Argument error: Need hex_id" unless $hex_id;

	my @rows=$self->retrieve_all(qq{hex_id = $hex_id});
	
	return unless @rows;
	
	return \@rows;
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

