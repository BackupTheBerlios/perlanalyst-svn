package Perl::Analysis::Static::DB;

=head1 NAME

  Perl::Analysis::Static::DB -- Connect to a database and execute SQL statements

=head1 SYNOPSIS

  my $db = Perl::Analysis::Static::DB->new(name => 'fu.db');
  
  my $success = $db->connect();
  my $success = $db->disconnect();

  my $success=execute($statement, $bindings);
  my $success=execute($statement);

  my $row=get_next_row();

=cut

use warnings;
use strict;

use base qw(Exporter);

use DBI;

use Perl::Analysis::Static::Log qw(debug message error);

our $VERSION   = 1.000;
our @EXPORT_OK = qw(connect_to_database get_database_handle);

our $db;

=head1 METHODS

=head2 new (@args)

Constructor.

  Perl::Analysis::Static::DB->new(name => 'fu.db');


=cut

sub new {
	my $that = shift;
	my $class = ref($that) || $that;

	my $self = {};
	bless $self, $class;

	my $args = {@_};

	for my $key (qw(name)) {
		$self->{$key} = $args->{$key} if $args->{$key};
	}

	# Encoding
	$self->{client_encoding} = $args->{client_encoding};

	$self->{dsn} = "dbi:SQLite:";

	$self->{dsn} .= "dbname=" . $self->{name} if $self->{name};

	# host and port if we are on a real db
	# $self->{dsn} .= ";host=$self->{host}" if $self->{host};
	# $self->{dsn} .= ";port=$self->{port}" if $self->{port};

	return $self;
}

=head2 DESTROY

Destructor. Finishes the statement and disconnects from the database.

=cut

sub DESTROY {
	my $self = shift;

	$self->_finish_statement();

	$self->disconnect() if $self->{dbh};
}

=head2 connect

Connect to the database.

AutoCommit is on, so any change in the database is visible at once.

Returns 1 on success or if we are already connected to the database.
Returns undef on error.

=cut

sub connect {
	my $self = shift;

	# success if we are connected already
	return 1 if $self->{dbh};

	# delete the latest statement handle. this might be a connect()
	# after a disconnect()
	delete $self->{sth};

	# try to connect
	eval {
		$self->{dbh} = DBI->connect(
			$self->{dsn},
			$self->{user},
			$self->{passwd},
			{
				RaiseError => 0,
				Taint      => 0,
				PrintError => 0,
				AutoCommit => 1
			}
		);
	};

	# failure?
	if ($@) {
		error("Unable to connect to database, reason: $@");
		return;
	}

	# another error?
	unless ( $self->{dbh} ) {
		my $reason = 'unknown';
		$reason = DBI->errstr() if DBI->err();
		error(  "Unable to connect to database, "
			  . "DSN is $self->{dsn}, reason: $reason" );
		return;
	}

	# we are connected now
	debug('Connection established');

	# if we don't want to set encoding we can leave now
	return 1 unless $self->{client_encoding};

	my $charset_quoted = $self->{dbh}->quote( $self->{client_encoding} );
	return 1
	  if $self->execute("SET client_encoding TO $charset_quoted");

	my $reason = 'unknown';
	$reason = DBI->errstr() if DBI->err();
	error("Unable to set client encoding, reason: $reason");

	# unable to set encoding, disconnect and leave
	$self->disconnect();

	return;
}

=head2 disconnect

Disconnect from the database.

Returns 1 if there wasn't a connection at all or if the disconnect succeeded.
Returns undef on failure.

=cut

sub disconnect {
	my $self = shift;

	# we aren't connected, return immediately
	return 1 unless $self->_connection_established();

	$self->_finish_statement();

	unless ( $self->{dbh}->disconnect() ) {
		my $reason = 'unknown';
		$reason = $self->{dbh}->errstr() if $self->{dbh}->err();
		error("Unable to disconnect, reason: $reason");
		return;
	}

	delete $self->{dbh};

	debug('Disconnect was successful');

	return 1;
}

=head2 execute ($statement, $bind_values)

Execute the SQL statement. The statement may have bindings, see L<DBD>
for an explanation of these.

It's legal to provide no bindings, i.e. just call

  $db->execute($statement);
  
Returns 1 if the execution was successful, undef on failure.

If the statement was a SELECT statement and its execution was successful,
you may get_next_row() until it fails to get the data.

=cut

sub execute {
	my ( $self, $statement, $bind_values ) = @_;

	# we need connection
	return unless $self->_connection_established();

	# empty statement?
	unless ($statement) {
		error('Unable to execute empty statement');
		return;
	}

	# we assume that we get data with this new statement
	$self->{no_more_data} = 0;

	$self->_finish_statement();

	# prepare the execution
	$self->{sth} = $self->{dbh}->prepare($statement);

	# failure upon preparation?
	unless ( $self->{sth} ) {
		my $reason = 'unknown';

		error(
			"Preparation of statement $statement " . "failed, reason $reason" );
		return;
	}

	my $result;
	debug("executing statement '$statement'");

	# execute with bindings if there are any
	if ( $bind_values and @$bind_values ) {
		$result = $self->{sth}->execute(@$bind_values);

		debug( 'Bindings: ', join( ',', @$bind_values ) );
	}
	else {

		# execute without bindings
		$result = $self->{sth}->execute();
	}

	# failure?
	unless ($result) {
		my $reason = 'unknown';
		$reason = $self->{sth}->errstr() if $self->{sth}->err();
		error(
			"Execution of statement $statement " . "failed, reason: $reason" );
		return;
	}

	# success, we may now fetch rows from the result table
	return 1;
}

=head2 get_next_row

Gets the next row from the result table and returns a reference of it.

Returns undef if there's was no data to fetch. It's safe to call this method
until it returns undef. It you call it again after it returned undef, you'll
see an error message.

The result is actually a copy of the result row, so it's safe to call this
method over and over again and store the results.

The result is a reference to a hash of which the keys are the column names in lower case.

=cut

sub get_next_row {
	my $self = shift;

	# are we called after we returned undef the last time?
	if ( $self->{no_more_data} ) {
		error("There are no more rows to fetch");
		return;
	}

	# no more data
	return unless $self->_fetch_next_row();

	# copy the result, DBI says the same hash might be used for different rows
	# in the future. yes, it's not very efficient
	my %copy = %{ $self->{current_row} };

	# return reference to the copy
	return \%copy;
}

=head1 INTERNAL METHODS

=head2 _connection_established

Are we connected to the database?

Returns 1 if so, undef otherwise.

=cut

sub _connection_established {
	my $self = shift;

	return unless $self->{dbh};

	return 1;
}

=head2 _finish_statement

Free buffers containing pending rows.

=cut

sub _finish_statement {
	my $self = shift;

	# there is no statement
	return unless exists $self->{sth};

	# free buffers if handle is active
	if ( $self->{sth}->{Active} ) {
		debug("discarding pending rows");
		$self->{sth}->finish();
	}

	# free the handle
	delete $self->{sth};
}

=head2 _fetch_next_row

Gets the next row from the result table. A reference to this row is stored
in the attribute C<current_row>. The row is represented as a hash reference.
We get the data by calling fetchrow_hashref with NAME_lc. See L<DBI> for a discussion
of these.

If there's no more data to fetch the attribute C<no_more_data> is set.

=cut

sub _fetch_next_row {
	my $self = shift;

	# no statement executed, so no data
	unless ( $self->{sth} ) {
		error("Fetching row failed, execute statement first");
		return;
	}

	# get one row
	$self->{current_row} = $self->{sth}->fetchrow_hashref('NAME_lc');

	unless ( $self->{current_row} ) {

		# do we have an error message?
		if ( $self->{sth}->err() ) {
			error(  "Fetching next row "
				  . "failed, reason: "
				  . $self->{sth}->errstr() );
			return;
		}

		# there's no more data to fetch
		$self->{no_more_data} = 1;
		return;
	}

	return 1;
}

=head1 FUNCTIONS

=head2 connect_to_database ($file)

Connects to database.

Returns undef if there was an error.

=cut

{
	# hide database handle in this scope so nobody is able to access it directly.
	# will be overwritten for each connect_to_database().
	my $db;

	sub connect_to_database {
		my ($file) = @_;

		# 'defined' allows a filename of '0'
		return error('Argument error: need file name') unless defined $file;

		$db = __PACKAGE__->new( name => $file );
		unless ($db) {
			return error("Unable to connect to database at file '$file'");
		}
	}

=head2 get_database_handle ()

Gets the database handle. If the database handle is undefined because you didn't
connect to the database you'll see an error message that tells you just this.

=cut

	sub get_database_handle {
		return error('There is no database handle to return') unless $db;
		return $db;
	}

=head2 table_exists ($table)

Does the table exist in the database?

=cut

	sub table_exists {
		my ($table) = @_;

		my @tables = $db->tables( undef, undef, undef, 'TABLE' );

		# this test is unneccessary but gives a debug message
		# if the list is empty
		unless (@tables) {
			debug('there are no tables in the database');
			return;
		}

		# yes, the name has double quotes around it!
		# (at least for sqlite...)
		return scalar grep( /^"$table"/, @tables );
	}

}
1;

=head1 AUTHOR

Gregor Goldbach E<lt>ggoldbach AT cpan DOT orgE<gt>

=head1 SEE ALSO

L<Perl::Analysis::Static>

=head1 COPYRIGHT

Copyright 2008 Gregor Goldbach. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
