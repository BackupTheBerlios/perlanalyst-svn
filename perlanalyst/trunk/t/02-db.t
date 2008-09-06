#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use PPI;
use PPI::Document;

my $module;

BEGIN {
	$module =
		'Perl::Analysis::Static::DB';

	use_ok($module) or BAIL_OUT;
}

my $file='t/data/foo.sqlite';
my $db=$module->new(name => $file, debug => 1);

use Data::Dumper; print Dumper($db);	

ok($db->connect(), 'connect');
ok($db->execute("CREATE TABLE files (path TEXT NOT NULL, PRIMARY KEY (path))"),
               'create table');
unlink $file;