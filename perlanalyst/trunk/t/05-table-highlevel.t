#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;
use Perl::Analysis::Static::Log qw(set_debug);
set_debug() if $ENV{TEST_VERBOSE};

my ( $module1, $module2 );

BEGIN {
	$module1 = 'Perl::Analysis::Static::Table';
	use_ok($module1) or BAIL_OUT;

	$module2 = 'Perl::Analysis::Static::DB';
	use_ok($module2, qw(connect_to_database) ) or BAIL_OUT;
}

my $file = 't/data/test.sqlite';
ok( connect_to_database($file), 'connect' );

my $db = $module2->new( name => $file );
ok( $db, 'db' );
ok ($db->connect(), 'connect');

my $table = $module1->new(
	db          => $db,
	name        => 'testtable',
	primary_key => 'file',
	columns     => [qw(file)]
);

ok( $table, 'table' );

# create
{
	my $expected = 1;
	my $got = $table->create();
	is( $got, $expected, 'create' );
}

# select
{
	my $expected = 1;    
	my $got      = $table->select();
	is( $got, $expected, 'select' );
}

# get the rows (table is empty)
{
	my $expected = undef;    
	my $got      = $table->get_next_row();
	is( $got, $expected, 'get next row' );
}

# insert
{
	my $expected = 1;    
	my $got      = $table->insert({file => 'foo'});
	is( $got, $expected, 'insert' );
}

# select
{
	my $expected = 1;    
	my $got      = $table->select();
	is( $got, $expected, 'select' );
}

# get the rows (table is empty)
{
	my $expected = { file => 'foo'};    
	my $got      = $table->get_next_row();
	is_deeply( $got, $expected, 'get next row (1)' );
}


# get the rows: there's only one row, so this ought to fail
{
	my $expected = undef;    
	my $got      = $table->get_next_row();
	is( $got, $expected, 'get next row (2)' );
}

END {unlink($file);}