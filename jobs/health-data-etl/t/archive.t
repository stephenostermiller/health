#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use FindBin;
use File::Spec;
use lib "$FindBin::Bin/../lib";

use HealthDataEtl::Archive qw(extract_metric_members extract_user_profile);

my $fixture_path = File::Spec->catfile($FindBin::Bin, 'fixtures', 'test-archive.tgz');

SKIP: {
	skip "test fixture not found", 1 unless -f $fixture_path;

	my @members = extract_metric_members($fixture_path);

	is(scalar(@members), 2, 'archive: extracts exactly 2 members');

	my %members_by_name = map { $_->{name} => $_ } @members;

	ok(exists $members_by_name{'weight.csv'}, 'archive: weight.csv present');
	ok(exists $members_by_name{'body_fat_2016-01-01.csv'}, 'archive: body_fat_2016-01-01.csv present');

	my $weight_content = $members_by_name{'weight.csv'}->{content};
	like($weight_content, qr/timestamp,weight grams,data source/, 'archive: weight.csv has header');

	my $bf_content = $members_by_name{'body_fat_2016-01-01.csv'}->{content};
	like($bf_content, qr/timestamp,body fat percentage,data source/, 'archive: body_fat has header');
}

done_testing();
