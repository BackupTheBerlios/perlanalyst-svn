#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
	my @modules = qw(
		Perl::Analysis::Static::Plugin::Location::FunctionCall
	);

	for my $module (@modules) {
		use_ok($module) or BAIL_OUT;
	}
}
#		Perl::Analysis::Static::Plugin::Location::FunctionCall->report();

