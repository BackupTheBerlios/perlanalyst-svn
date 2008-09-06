#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

my $module;

BEGIN {
	$module = 'Perl::Analysis::Static::ColumnType';

	use_ok( $module, qw(set_column_type get_column_type) ) or BAIL_OUT;
}

# set and get column type
{
	my $type = 'TEXT NOT NULL';

	{
		my $expected = 1;
		my $got = set_column_type( 'hex_id', $type );

		is( $got, $expected, 'set hex_id' );
	}

	{
		my $expected = $type;
		my $got      = get_column_type('hex_id');

		is( $got, $expected, 'get hex_id' );
	}

}

# get non-existing column type
{
	{
		my $expected = undef;
		my $got      = get_column_type('id');

		is( $got, $expected, 'get non-existing column type' );
	}    
}
