#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use HealthDataEtl::Archive;
use HealthDataEtl::Normalize qw(normalize_weight_row normalize_body_fat_row normalize_user_profile_row);
use HealthDataEtl::DB qw(connect_db load_facts load_user refresh_aggregates);

my $source = @ARGV ? $ARGV[0] : \*STDIN;

die "Usage: etl.pl [FILE.tgz]  (or pipe a .tgz on stdin)\n"
	if @ARGV && !-f $ARGV[0];

my $user_id = $ENV{PRIMARY_USER_ID} || 45016898;

my $dbh = connect_db();

# Extract all contents from archive in a single pass
my $archive_contents = HealthDataEtl::Archive::extract_archive_contents($source);

# Load user profile if available
if ($archive_contents->{user_profile}) {
	my @lines = split /\n/, $archive_contents->{user_profile};
	shift @lines;  # skip header
	for my $line (@lines) {
		next unless $line =~ /\S/;
		my $user = normalize_user_profile_row($line);
		if (defined $user) {
			load_user($dbh, $user);
			my $email = $user->{user_name};
			print "User profile loaded. Login to dashboard with: $email\n";
		}
	}
}

# Load metric facts
my @members = @{$archive_contents->{metrics}};

my @facts;
for my $member (@members) {
	my $name = $member->{name};
	my $content = $member->{content};

	# Split content into lines and skip header
	my @lines = split /\n/, $content;
	shift @lines;  # skip header

	if ($name eq 'weight.csv') {
		for my $line (@lines) {
			next unless $line =~ /\S/;
			my $fact = normalize_weight_row($line);
			push @facts, {%$fact, user_id => $user_id} if defined $fact;
		}
	} elsif ($name =~ /^body_fat_/) {
		for my $line (@lines) {
			next unless $line =~ /\S/;
			my $fact = normalize_body_fat_row($line);
			push @facts, {%$fact, user_id => $user_id} if defined $fact;
		}
	}
}

if (@facts) {
	load_facts($dbh, \@facts, $user_id);
	refresh_aggregates($dbh);
	print "Loaded ", scalar(@facts), " facts\n";
} else {
	print "No facts to load\n";
}
