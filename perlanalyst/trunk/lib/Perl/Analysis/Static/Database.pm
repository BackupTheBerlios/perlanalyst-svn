package Perl::Analysis::Static::Database;

=head1 NAME

  Perl::Analysis::Static::Database -- Basic database functionality
  
=head1 DESCRIPTION

Information collected by the plugins is stored in a database. This module
has functions that set up the database and provide access to the tables in it.

=cut

use strict;
use warnings;

use Carp;
use DBI;
use DBD::SQLite;
use Class::DBI;

use Perl::Analysis::Static::Plugins qw(get_plugins_that_can_analyze);
use Perl::Analysis::Static::Log qw(message debug);
#use Perl::Analysis::Static::PluginList qw(create_plugin_list_table);

use base qw(Exporter);

our $VERSION   = 1.000;
our @EXPORT_OK = qw(set_database_file connect_to_database
	table_exists create_table create_tables do_sql);

# this is where everything's kept
our $database_file;

our $dbh;

=head1 FUNCTIONS

=head2 set_database_file ($file)

=cut

sub set_database_file {
	my ($file) = @_;

	debug("Setting db file to '$file'");
	$database_file = $file;
}

=head2 connect_to_database

=cut

sub connect_to_database {

	# we must have the database location defined
	unless ($database_file) {
		croak('No database file defined');
	}

	# we have to use Class::DBI's attributes
	my %attr = Class::DBI->_default_attributes();

	my $DSN = "dbi:SQLite:dbname=$database_file";

	# connect to database and set package-wide handle
	$dbh = DBI->connect( $DSN, '', '', \%attr );
	unless ($dbh) {
		croak("Error connecting to database at $DSN");
	}
}

sub table_exists {
	my ($table) = @_;

	my @tables = $dbh->tables( undef, undef, undef, 'TABLE' );

	# this test is unneccessary but gives a debug message
	# if the list is empty
	unless (@tables) {
		debug('there are no tables in the database');
		return 0;
	}

	# yes, the name has double quotes around it!
	# (at least for sqlite...)
	return scalar grep( /^"$table"/, @tables );
}

=head2 _create_index_table

Creates table C<files> where the file informations for the index
are stored.

=cut

sub _create_index_table {

	return 1 if table_exists('files');

	# table for the files
	my $create = <<'END_SQL';
CREATE TABLE files (
	path    TEXT    NOT NULL,
	checked INTEGER NOT NULL,
	hex_id  TEXT    NOT NULL,
	PRIMARY KEY (path)
)
END_SQL

	# Execute the table creation SQL
	$dbh->do($create)
		or croak( "Error creating database table", $dbh->errstr );

	return 1;

}

=head2 _create_pluginlist_table

Creates table C<pluginlist> where the informations for the list of plugins stored.

=cut

sub _create_pluginlist_table {

	return 1 if table_exists('pluginlist');

	# table for the files
	my $create = <<'END_SQL';
CREATE TABLE pluginlist (
	name    TEXT    NOT NULL,
	version INTEGER NOT NULL,
	PRIMARY KEY (name)
)
END_SQL

	# Execute the table creation SQL
	$dbh->do($create)
		or croak( "Error creating database table", $dbh->errstr );

	return 1;

}

=head2 _create_pluginranforfile_table

Creates table C<pluginranforfile>.

=cut

sub _create_pluginranforfile_table {

	return 1 if table_exists('pluginranforfile');
	
	my $create = <<'END_SQL';
CREATE TABLE pluginranforfile (
	name    TEXT    NOT NULL,
	file    TEXT NOT NULL,
	PRIMARY KEY (name, file)
)
END_SQL

	# Execute the table creation SQL
	$dbh->do($create)
		or croak( "Error creating database table", $dbh->errstr );

	return 1;

}

=head2 create_tables

Creates the index table and tables for the plugins.

=cut

sub create_tables {
	_create_index_table();

	_create_pluginlist_table();
    _create_pluginranforfile_table();
	
	# we only need to create tables for plugins that can analyze
	my @plugins = get_plugins_that_can_analyze();
	message( 'Creating tables for ' . scalar @plugins . ' plugin(s)' )
		;    

	for my $plugin (@plugins) {
		my $p = $plugin->new();
		$p->setup_table();
	}

}

sub create_table {
	my ($plugin) = @_;

	my $statement = $plugin->build_create_table_string();

	unless ( $dbh->do($statement) ) {
		croak( 'Error creating database table', $dbh->errstr );
	}

	return 1;
}

=head2 do_sql ($statement)

This is just a wrapper for DBI's do() so we don't have to export
the database handle.

If it fails it croaks.

=cut

sub do_sql {
	my ($statement)=@_;
	
	unless ( $dbh->do($statement) ) {
		croak( "Error executing statement '$statement'", $dbh->errstr );
	}

}

1;

=head1 AUTHOR

Gregor Goldbach E<lt>ggoldbach AT cpan DOT orgE<gt>

=head1 SEE ALSO

L<Perl::Analysis::Static::Plugins>

=head1 COPYRIGHT

Copyright 2008 Gregor Goldbach. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
