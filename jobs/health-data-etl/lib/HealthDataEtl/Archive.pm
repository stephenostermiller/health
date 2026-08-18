package HealthDataEtl::Archive;

use strict;
use warnings;

use Archive::Tar;
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use Exporter 'import';

our @EXPORT_OK = qw(extract_archive_contents extract_metric_members extract_user_profile);

sub extract_archive_contents {
	my ($source) = @_;

	my $gz = IO::Uncompress::Gunzip->new($source)
		or die "gunzip failed: $GunzipError\n";

	my $tar = Archive::Tar->new;
	$tar->read($gz);

	my @metrics;
	my $user_profile;

	for my $entry ($tar->get_files) {
		next unless $entry->is_file;
		my $path = $entry->full_path;
		my $content = $entry->get_content;

		# Extract user profile
		if ($path =~ m{(?:^|/)User Profile_GoogleData/user_profile\.csv$}) {
			$user_profile = $content;
		}

		# Extract metric files
		if ($path =~ m{(?:^|/)Physical Activity_GoogleData/(weight\.csv|body_fat_\d{4}-\d{2}-\d{2}\.csv)$}) {
			push @metrics, {
				name => $1,
				content => $content,
			};
		}
	}

	return {
		user_profile => $user_profile,
		metrics => \@metrics,
	};
}

sub extract_metric_members {
	my ($source) = @_;

	my $contents = extract_archive_contents($source);
	return @{$contents->{metrics}};
}

sub extract_user_profile {
	my ($source) = @_;

	my $contents = extract_archive_contents($source);
	return $contents->{user_profile};
}

1;
