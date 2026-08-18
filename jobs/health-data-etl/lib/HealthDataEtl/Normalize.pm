package HealthDataEtl::Normalize;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(normalize_weight_row normalize_body_fat_row parse_takeout_timestamp normalize_user_profile_row);

sub parse_takeout_timestamp {
	my ($ts_str) = @_;
	return undef unless defined $ts_str && $ts_str =~ /\S/;

	if ($ts_str =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})Z$/) {
		return "$1-$2-$3 $4:$5:$6";
	}
	return undef;
}

sub normalize_weight_row {
	my ($line) = @_;
	chomp $line;
	$line =~ s/\r$//;
	my ($timestamp_str, $grams_str, $data_source) = split(',', $line, -1);

	my $timestamp = parse_takeout_timestamp($timestamp_str);
	return undef unless defined $timestamp;

	return undef unless defined $grams_str && $grams_str =~ /^\d+(?:\.\d+)?$/;

	my $pounds = $grams_str / 453.6;

	return {
		timestamp => $timestamp,
		metric => 'weight',
		unit => 'lb',
		value => $pounds,
		data_source => $data_source && $data_source =~ /\S/ ? $data_source : undef,
	};
}

sub normalize_body_fat_row {
	my ($line) = @_;
	chomp $line;
	$line =~ s/\r$//;
	my ($timestamp_str, $percentage_str, $data_source) = split(',', $line, -1);

	my $timestamp = parse_takeout_timestamp($timestamp_str);
	return undef unless defined $timestamp;

	return undef unless defined $percentage_str && $percentage_str =~ /^\d+(?:\.\d+)?$/;

	return {
		timestamp => $timestamp,
		metric => 'body_fat',
		unit => '%',
		value => $percentage_str,
		data_source => $data_source && $data_source =~ /\S/ ? $data_source : undef,
	};
}

sub normalize_user_profile_row {
	my ($line) = @_;
	chomp $line;
	$line =~ s/\r$//;

	my @fields = split(',', $line, -1);
	return undef if @fields < 11;

	my ($fitbit_id, $encoded_fitbit_id, $email, $first_name, $last_name, $display_name, $birthday, $gender, $country, $timezone, $creation_time) = @fields;

	return undef unless $fitbit_id && $fitbit_id =~ /^\d+$/;

	my $user_gender = undef;
	if ($gender eq 'SEX_MALE') {
		$user_gender = 'male';
	} elsif ($gender eq 'SEX_FEMALE') {
		$user_gender = 'female';
	}

	my $birthdate = undef;
	if ($birthday && $birthday =~ /^\d{4}-\d{2}-\d{2}$/) {
		$birthdate = $birthday;
	}

	my $name = $first_name || $display_name || '';
	$name = substr($name, 0, 20);

	my $user_name = $email;

	my $initials = '';
	if ($first_name && $last_name) {
		$initials = substr($first_name, 0, 1) . substr($last_name, 0, 1);
	} elsif ($first_name) {
		$initials = substr($first_name, 0, 1);
	}
	$initials = $initials && length($initials) > 0 ? $initials : undef;

	return {
		id => $fitbit_id,
		name => $name,
		birthdate => $birthdate,
		gender => $user_gender,
		user_name => $user_name,
		initials => $initials,
	};
}

1;
