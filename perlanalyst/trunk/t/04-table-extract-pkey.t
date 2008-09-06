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

	isa_ok( $table, $module1 );

	my $expected = { file => 'foo' };
	my $got = $table->extract_pkey(
		{ file => 'foo', argl => 'kargh', hsl => 'grmph' } );
	is_deeply( $got, $expected, 'single column' );
}

# create, primary key is three columns
{
	my $table = $module1->new(
		name        => 'testtable',
		primary_key => [qw(file name version)],
		columns     => [qw(file name version)]
	);

	isa_ok( $table, $module1 );

	my $expected = { file => 'foo', name => 'test', version => 1 };
	my $got = $table->extract_pkey(
		{
			file    => 'foo',
			argl    => 'kargh',
			hsl     => 'grmph',
			name    => 'test',
			version => 1
		}
	);
	is_deeply( $got, $expected, 'three columns' );
}

END { unlink($file) }
