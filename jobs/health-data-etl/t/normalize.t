#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use HealthDataEtl::Normalize qw(
	normalize_weight_row
	normalize_body_fat_row
	parse_takeout_timestamp
	normalize_user_profile_row
);

# Test parse_takeout_timestamp
is(parse_takeout_timestamp('2016-01-22T19:20:40Z'), '2016-01-22 19:20:40', 'parse_takeout_timestamp: valid ISO-8601');
is(parse_takeout_timestamp(''), undef, 'parse_takeout_timestamp: empty string');
is(parse_takeout_timestamp(undef), undef, 'parse_takeout_timestamp: undef');
is(parse_takeout_timestamp('2016-01-22 19:20:40'), undef, 'parse_takeout_timestamp: malformed (no Z)');
is(parse_takeout_timestamp('invalid'), undef, 'parse_takeout_timestamp: invalid');

# Test normalize_weight_row
my $weight_fact = normalize_weight_row('2016-01-22T19:20:40Z,103840,Aria');
ok(defined $weight_fact, 'normalize_weight_row: returns fact');
is($weight_fact->{timestamp}, '2016-01-22 19:20:40', 'normalize_weight_row: timestamp');
is($weight_fact->{metric}, 'weight', 'normalize_weight_row: metric');
is($weight_fact->{unit}, 'lb', 'normalize_weight_row: unit');
is($weight_fact->{data_source}, 'Aria', 'normalize_weight_row: data_source');
ok(abs($weight_fact->{value} - 228.924162) < 0.000001, 'normalize_weight_row: value (grams to pounds)');

# Test weight with blank data_source
my $weight_fact_blank = normalize_weight_row('2016-01-22T19:20:40Z,103840,');
ok(defined $weight_fact_blank, 'normalize_weight_row: blank data_source returns fact');
is($weight_fact_blank->{data_source}, undef, 'normalize_weight_row: blank data_source becomes undef');

# Test weight with invalid timestamp
is(normalize_weight_row('invalid,103840,Aria'), undef, 'normalize_weight_row: invalid timestamp returns undef');

# Test weight with invalid grams
is(normalize_weight_row('2016-01-22T19:20:40Z,invalid,Aria'), undef, 'normalize_weight_row: invalid grams returns undef');

# Test normalize_body_fat_row
my $bf_fact = normalize_body_fat_row('2020-03-01T12:09:51Z,30.087,Aria');
ok(defined $bf_fact, 'normalize_body_fat_row: returns fact');
is($bf_fact->{timestamp}, '2020-03-01 12:09:51', 'normalize_body_fat_row: timestamp');
is($bf_fact->{metric}, 'body_fat', 'normalize_body_fat_row: metric');
is($bf_fact->{unit}, '%', 'normalize_body_fat_row: unit');
is($bf_fact->{data_source}, 'Aria', 'normalize_body_fat_row: data_source');
ok(abs($bf_fact->{value} - 30.087) < 0.000001, 'normalize_body_fat_row: value');

# Test body_fat with blank data_source
my $bf_fact_blank = normalize_body_fat_row('2020-03-01T12:09:51Z,30.087,');
ok(defined $bf_fact_blank, 'normalize_body_fat_row: blank data_source returns fact');
is($bf_fact_blank->{data_source}, undef, 'normalize_body_fat_row: blank data_source becomes undef');

# Test body_fat with invalid timestamp
is(normalize_body_fat_row('invalid,30.087,Aria'), undef, 'normalize_body_fat_row: invalid timestamp returns undef');

# Test body_fat with invalid percentage
is(normalize_body_fat_row('2020-03-01T12:09:51Z,invalid,Aria'), undef, 'normalize_body_fat_row: invalid percentage returns undef');

# Test normalize_user_profile_row
my $user = normalize_user_profile_row('45016898,47G65D,stosterm@gmail.com,Stephen,Ostermiller,Stephen O.,1976-11-27,SEX_MALE,US,America/New_York,2016-01-22T19:11:36Z');
ok(defined $user, 'normalize_user_profile_row: returns user');
is($user->{id}, '45016898', 'normalize_user_profile_row: id');
is($user->{name}, 'Stephen', 'normalize_user_profile_row: name (first_name)');
is($user->{birthdate}, '1976-11-27', 'normalize_user_profile_row: birthdate');
is($user->{gender}, 'male', 'normalize_user_profile_row: gender (SEX_MALE -> male)');
is($user->{user_name}, 'stosterm@gmail.com', 'normalize_user_profile_row: user_name (email)');
is($user->{initials}, 'SO', 'normalize_user_profile_row: initials (first+last)');

# Test user profile with female gender
my $user_f = normalize_user_profile_row('12345,XX1YZ,jane@example.com,Jane,Doe,Jane D.,1980-01-15,SEX_FEMALE,US,America/New_York,2020-01-01T00:00:00Z');
is($user_f->{gender}, 'female', 'normalize_user_profile_row: gender (SEX_FEMALE -> female)');

# Test user profile with empty display_name (user_name should be email)
my $user_no_display = normalize_user_profile_row('54321,YY2ZW,bob@example.com,Bob,Smith,,1975-05-10,SEX_MALE,US,America/New_York,2015-01-01T00:00:00Z');
is($user_no_display->{user_name}, 'bob@example.com', 'normalize_user_profile_row: user_name is email address');

# Test user profile with invalid id
is(normalize_user_profile_row('invalid_id,XX3AB,test@example.com,Test,User,Test User,1990-01-01,SEX_MALE,US,America/New_York,2020-01-01T00:00:00Z'), undef, 'normalize_user_profile_row: invalid id returns undef');

done_testing();
