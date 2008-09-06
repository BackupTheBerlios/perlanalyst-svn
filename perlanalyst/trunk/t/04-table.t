#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;

my ( $module1, $module2 );

BEGIN {
	$module1 = 'Perl::Analysis::Static::Table';
	use_ok($module1) or BAIL_OUT;

	$module2 = 'Perl::Analysis::Static::DB';
	use_ok( $module2, qw(connect_to_database) ) or BAIL_OUT;
}

my $file = 't/data/test.sqlite';
ok( connect_to_database($file), 'connect' );

my $table = $module1->new(
	name        => 'testtable',
	primary_key => 'file',
	columns     => [qw(file)]
);

ok( $table, 'table' );

# select
{
	my $expected = 'SELECT * FROM testtable';
	my $got      = $table->_select();
	is( $got, $expected, 'select string' );
}

# insert
{
	my $expected = "INSERT INTO testtable (file) VALUES ('foo')";
	my $got = $table->_insert( { file => 'foo' } );
	is( $got, $expected, 'insert string' );
}

# update
{
	my $expected = "UPDATE testtable SET file = 'foo'";
	my $got = $table->_update( { file => 'foo' } );
	is( $got, $expected, 'update string' );
}

# update with where
{
	my $expected = "UPDATE testtable SET file = 'foo' WHERE a>2";
	my $got = $table->_update( { file => 'foo', where => 'a>2' } );
	is( $got, $expected, 'update with where string' );
}

# delete
{
	my $expected = "DELETE FROM testtable";
	my $got      = $table->_delete();
	is( $got, $expected, 'delete string' );
}

# delete with where
{
	my $expected = "DELETE FROM testtable  WHERE a>2";
	my $got = $table->_delete( { where => 'a>2' } );
	is( $got, $expected, 'delete with where string' );
}

END { unlink($file) }
