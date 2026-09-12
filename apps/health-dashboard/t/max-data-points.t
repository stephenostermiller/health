#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 5;

use lib 'lib';
use HealthDashboard::Queries qw(max_data_points);

# Test 1: max_data_points is exported and callable
ok(defined(&max_data_points), 'max_data_points function is exported');

# Test 2: max_data_points returns a value
my $limit = max_data_points();
ok(defined $limit, 'max_data_points returns a value');

# Test 3: max_data_points returns 800
is($limit, 800, 'max_data_points returns 800');

# Test 4: max_data_points returns an integer
ok($limit =~ /^\d+$/, 'max_data_points returns an integer');

# Test 5: max_data_points is consistent across calls
my $limit2 = max_data_points();
is($limit, $limit2, 'max_data_points returns consistent value');

done_testing();
