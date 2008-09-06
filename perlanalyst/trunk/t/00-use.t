#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 15;

BEGIN {
	my @modules = qw(Perl::Analysis::Static::Database
		Perl::Analysis::Static::Analysis
		Perl::Analysis::Static::DBI
		Perl::Analysis::Static::File
		Perl::Analysis::Static::Log
		Perl::Analysis::Static::Plugin
		Perl::Analysis::Static::PluginList
		Perl::Analysis::Static::PluginRanForFile
		Perl::Analysis::Static::Plugins
		Perl::Analysis::Static::Plugin::Location
		Perl::Analysis::Static::Plugin::OncePerFile
		Perl::Analysis::Static::Plugin::Location::FunctionCall
		Perl::Analysis::Static::Plugin::Location::BuiltinCall
		Perl::Analysis::Static::Plugin::Location::Package
		Perl::Analysis::Static::Plugin::OncePerFile::One
	);

	for my $module (@modules) {
		use_ok($module) or BAIL_OUT;
	}
}

