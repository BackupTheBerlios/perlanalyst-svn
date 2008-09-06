package Perl::Analysis::Static::Table;

=head1 NAME

  Perl::Analysis::Static::Table - Table

=head1 DESCRIPTION

Very basic class that represents a table in a database. There are methods to create a table,
insert rows, get rows from the table, update rows and delete rows. These methods are all using
a method that's able to execute arbitrary SQL statements.

Beware: Currently there's neither quoting or creation of bindings.  

=cut

use warnings;
use strict;

use Perl::Analysis::Static::Log qw(debug error);
use Perl::Analysis::Static::ColumnType qw(get_column_type);
use Perl::Analysis::Static::DB qw(get_database_handle);

our $VERSION = 1.000;

=head1 METHODS

=head2  new

=cut

sub new {
	my $that = shift;
	my $class = ref($that) || $that;

	my $self = {};

	bless $self, $class;

	return error('initialization of table instance failed')
	  unless $self->_init(@_);

	return $self;
}

sub execute {
	my ( $self, $statement, $bind_values ) = @_;

	return unless $self->_check_for_db_connection();

	return $self->{db}->execute( $statement, $bind_values );
}

sub select {
	my ( $self, $args ) = @_;

	$args->{table} = $self->{name};

	my $statement = $self->_select($args);

	return unless $statement;

	return $self->execute($statement);
}

sub get_next_row {
	my $self = shift;

	return unless $self->_check_for_db_connection();
	return $self->{db}->get_next_row();
}

sub insert {
	my ( $self, $args ) = @_;

	my $statement = $self->_insert($args);
	
	return unless $statement;

	return $self->execute($statement);
}

sub delete {
	my ( $self, $args ) = @_;

	my $statement = $self->_delete($args);

	return unless $statement;

	return $self->execute($statement);
}

sub update {
	my ( $self, $args ) = @_;

	my $statement = $self->_update($args);

	return unless $statement;

	return $self->execute($statement);
}

sub create {
	my ($self) = @_;

	return $self->execute( $self->_create() );
}

=head1 INTERNAL METHODS

=cut

sub _init {
	my $self = shift;

	my $args = {@_};

	# required arguments
	for my $attr (qw(name primary_key columns)) {
		unless ( exists $args->{$attr} ) {
			error( "attribute $attr is required upon initialisation" );
			return;
		}

		$self->{$attr} = $args->{$attr};
	}

	# sanity check: columns has to be list reference
	unless ( ref( $self->{columns} )
		and ( ref( $self->{columns} ) eq 'ARRAY' ) )
	{
		error('columns has to be list reference');
		return;
	}

	# get database handle and check it
	$self->{db} = get_database_handle();
	unless ( $self->{db} ) {
		return error(
			'Unable to get database handle, connect to database first');
	}

	return 1;
}

sub _check_for_db_connection {
	my $self = shift;

	unless ( $self->{db} ) {
		return error('Database object undefined');
	}

	unless ( $self->{db}->connect() ) {
		return error('Database connect is unable to establish a connection');
	}

	return 1;
}

sub _references_nonempty_hash {
	my $arg = shift;

	# is it defined?
	return unless $arg;

	# is it a reference to a hash?
	return unless ref($arg) eq 'HASH';

	# is it non-empty?
	return unless keys %$arg;

	return 1;
}

sub _create {
	my ($self) = @_;

	my $t = $self->{name};

	my $columns;
	for my $column ( @{ $self->{columns} } ) {
		$columns .= $column . ' ' . get_column_type($column) . ', ';
	}

	my $pkey = $self->{primary_key};

	# does the primary key consist of more than one column?
	if (ref($pkey) eq 'ARRAY' ) {
		$pkey = join(', ', @$pkey);
	}

	return "CREATE TABLE $t (${columns}PRIMARY KEY ($pkey))";
}

sub _select {
	my ( $self, $hashref ) = @_;

	my $base = 'SELECT * FROM ' . $self->{name};
	return $base unless $hashref;

	unless ( _references_nonempty_hash($hashref) ) {
		return error('Method needs a filled hash reference as argument');
	}

	# add "order by"-clause?
	my $order_by = '';
	if ( exists $hashref->{order_by} ) {
		$order_by = ' ORDER BY ' . $hashref->{order_by};
	}

	# add where clause?
	my $where    = '';
	if ( exists $hashref->{where} ) {
		$where = ' WHERE ' . $hashref->{where};
	}

	return $base . $where . $order_by;
}

sub _insert {
	my ( $self, $hashref ) = @_;

	my $base = 'INSERT INTO ' . $self->{name};

	unless ( _references_nonempty_hash($hashref) ) {
		return error('Method needs a filled hash reference as argument');
	}

	my @columns;
	my @values;

	for my $key ( keys %$hashref ) {
		push @columns, $key;

		# surround value with single quotes
		push @values, "'$hashref->{$key}'";
	}

	my $columns = join( ',', @columns );
	my $values  = join( ',', @values );

	return "$base ($columns) VALUES ($values)";
}

sub _update {
	my ( $self, $hashref ) = @_;

	my $base  = 'UPDATE ' . $self->{name} . ' SET';

	unless ( _references_nonempty_hash($hashref) ) {
		error("Method needs a filled hash reference as argument");
		return;
	}

	my @assignments;

	for my $key ( keys %$hashref ) {

		# skip where clause
		next if $key eq 'where';

		push @assignments, "$key = '" . $hashref->{$key} . "'";
	}

	my $assignments = join( ',', @assignments );

	# add where clause?
	my $where = '';
	if ( exists $hashref->{where} ) {
		$where = ' WHERE ' . $hashref->{where};
	}

	return "$base $assignments$where";
}

sub _delete {
	my ( $self, $hashref ) = @_;

	my $base  = 'DELETE FROM ' . $self->{name};

	return $base unless $hashref;

	unless ( _references_nonempty_hash($hashref) ) {
		return error('Method needs a filled hash reference as argument');
		
	}

	# add where clause?
	my $where = '';
	if ( exists $hashref->{where} ) {
		$where = " WHERE " . $hashref->{where};
	}

	return "$base $where";
}

sub pkey_exists {
	my ( $self, $hashref ) = @_;

	# todo: extract only those columns from hasref which are in the pkey

	$self->select($hashref);
	my $row=$self->get_row();
	
	return defined $row;
}	

=head2 store ($row)

Store the row in the table. If a row with this primary key already exists, update date it, otherwise
just insert it.

=cut

sub store {
	my ( $self, $row ) = @_;

	if ($self->pkey_exists($row)) {
		return $self->update($row);
	}

	$self->insert($row);
}

=head2 extract_pkey ($row)

Extract the primary key columns from the row.
Copies the columns from the argument row that are columns in the primary key.

Returns reference to copy or undef if a column couldn't been found in the row.

=cut

sub extract_pkey {
	my ( $self, $row ) = @_;

	my %extract;
	
	my $pkey=$self->{primary_key};
	
	# turn it into a list reference if it's a single column
	$pkey = [$pkey] unless ref($pkey);

	for my $column (@$pkey) {
		unless (exists $row->{$column}) {
			return error("Column '$column' is not in the row");
		}
		
		$extract{$column}=$row->{$column};
	}

	return \%extract;
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

