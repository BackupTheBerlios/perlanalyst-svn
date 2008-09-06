#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
	my @modules = qw(Perl::Analysis::Static::Configuration);

	for my $module (@modules) {
		use_ok($module, qw(read_configuration get_config)) or BAIL_OUT;
	}
}

{
	my $file='t/data/foo';
	
	eval {read_configuration($file)};
	
	ok($@, 'error loading non-existent file');
}

{
	my $file='t/data/config.cfg';
	
	my $got=read_configuration($file);
	my $expected=1;
	
	is($got, $expected, 'existing file');
}

{
	my $got=get_config('database');
	my $expected='foo';
	
	is($got, $expected, 'get config entry');
}

