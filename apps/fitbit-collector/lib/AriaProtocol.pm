package AriaProtocol;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(
	UNIT_POUNDS UNIT_STONE UNIT_KILOGRAMS
	STATUS_CONFIGURED STATUS_UNCONFIGURED
	GENDER_MALE GENDER_FEMALE GENDER_UNKNOWN
	gender_to_enum
	age_from_birthdate
	encode_name_field
);

# Unit types for aria_upload_response_body3
use constant UNIT_POUNDS => 0;
use constant UNIT_STONE => 1;
use constant UNIT_KILOGRAMS => 2;

# Status types for aria_upload_response_body3
use constant STATUS_CONFIGURED => 0x32;
use constant STATUS_UNCONFIGURED => 0x64;

# Gender types for aria_user
use constant GENDER_MALE => 0x02;
use constant GENDER_FEMALE => 0x00;
use constant GENDER_UNKNOWN => 0x34;

# Convert database gender value to protocol enum code
sub gender_to_enum {
	my ($db_value) = @_;

	return GENDER_UNKNOWN unless defined $db_value;

	my $normalized = lc($db_value);

	if ($normalized eq 'male' || $normalized eq 'm' || $db_value == 1) {
		return GENDER_MALE;
	} elsif ($normalized eq 'female' || $normalized eq 'f' || $db_value == 0) {
		return GENDER_FEMALE;
	} else {
		return GENDER_UNKNOWN;
	}
}

# Calculate age in years from birthdate (YYYY-MM-DD format)
sub age_from_birthdate {
	my ($birthdate) = @_;

	return 0 unless defined $birthdate;

	my ($birth_year, $birth_month, $birth_day) = split /-/, $birthdate;
	return 0 unless $birth_year && $birth_month && $birth_day;

	my @now = localtime();
	my $current_year = $now[5] + 1900;
	my $current_month = $now[4] + 1;
	my $current_day = $now[3];

	my $age = $current_year - $birth_year;
	if ($current_month < $birth_month || ($current_month == $birth_month && $current_day < $birth_day)) {
		$age--;
	}

	return $age;
}

# Encode name field for Aria protocol (ASCII, fixed 20-byte field)
# The Aria protocol uses char[20] which is ASCII only
sub encode_name_field {
	my ($name) = @_;

	return '' unless defined $name;

	# Convert to ASCII, replacing non-ASCII characters with '?'
	my $ascii_name = '';
	for my $char (split //, $name) {
		my $ord = ord($char);
		if ($ord < 128) {
			$ascii_name .= $char;
		} else {
			$ascii_name .= '?';  # replace non-ASCII with placeholder
		}
	}

	# Pack into fixed 20-byte field (pad with spaces or truncate)
	return pack('A20', $ascii_name);
}

1;
