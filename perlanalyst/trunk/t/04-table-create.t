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

# create, primary key is one column
{
	my $table = $module1->new(
		name        => 'testtable',
		primary_key => 'file',
		columns     => [qw(file)]
	);

	ok( $table, 'table' );

	my $expected =
	  'CREATE TABLE testtable (file TEXT NOT NULL, PRIMARY KEY (file))';
	my $got = $table->_create();
	is( $got, $expected, 'creation string' );
}


# create, primary key is three columns
{
	my $table = $module1->new(
		name        => 'testtable',
		primary_key => [qw(file name version)],
		columns     => [qw(file name version)]
	);

	ok( $table, 'table' );

	my $expected =
	  'CREATE TABLE testtable (file TEXT NOT NULL, name TEXT NOT NULL, version INTEGER, PRIMARY KEY (file, name, version))';
	my $got = $table->_create();
	is( $got, $expected, 'creation string' );
}

END { unlink($file) }
