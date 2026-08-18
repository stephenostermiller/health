package ResponseBuilder;

use strict;
use warnings;

use Exporter 'import';
use POSIX qw(time);
use CRC qw(crc16_xmodem);
use AriaProtocol qw(UNIT_POUNDS STATUS_CONFIGURED GENDER_UNKNOWN gender_to_enum age_from_birthdate encode_name_field);

our @EXPORT_OK = qw(build_response);

# based on https://github.com/cequencer/helvetic/blob/a64b6faed38ad2b174144906724508b5aed6cb07/protocol.md

sub build_response {
	my (%opts) = @_;

	my $dbh = $opts{dbh} or die "dbh is required\n";
	my $user_id = $opts{user_id} or die "user_id is required\n";

	my $current_timestamp = time();
	my $units = UNIT_POUNDS;
	my $status = STATUS_CONFIGURED;
	my $user_count = 1;

	my $body = '';
	$body .= _write_u32le($current_timestamp);
	$body .= chr($units);
	$body .= chr($status);
	$body .= chr(0x01);
	$body .= _write_u32le($user_count);

	my $user = _build_user($dbh, $user_id);
	$body .= $user;

	$body .= _write_u32le(0x03);
	$body .= _write_u32le(0);

	my $crc = crc16_xmodem($body);
	my $envelope = $body . _write_u16le($crc) . chr(0x66) . chr(0x00);

	return $envelope;
}

sub _build_user {
	my ($dbh, $user_id) = @_;

	my $user_row = $dbh->selectrow_hashref(
		'SELECT id, name, birthdate, gender, height_mm, initials FROM `user` WHERE id = ?',
		undef,
		$user_id
	) or die "User $user_id not found\n";

	my $initials = $user_row->{initials};
	my $name_to_send = $initials || $user_row->{name} || $user_id;
	my $age = age_from_birthdate($user_row->{birthdate});
	my $gender = gender_to_enum($user_row->{gender});
	my $height_mm = $user_row->{height_mm} // 0;

	my $user = '';
	$user .= _write_u32le($user_id);
	$user .= pack('C16', 0) x 1;                  # padding
	$user .= encode_name_field($name_to_send);    # initials (if set), name, or user_id: ASCII, fixed 20-byte field
	$user .= _write_u32le(0);                     # min_weight_tolerance
	$user .= _write_u32le(100000000);             # max_weight_tolerance
	$user .= _write_u32le($age);
	$user .= chr($gender);
	$user .= _write_u32le($height_mm);
	$user .= _write_u32le(0);                     # weight1 (previous known value)
	$user .= _write_u32le(0);                     # body_fat (previous known value)
	$user .= _write_u32le(0);                     # covariance (previous known value)
	$user .= _write_u32le(0);                     # weight2 (previous known value)
	$user .= _write_u32le(0);                     # timestamp
	$user .= _write_u32le(0);                     # unknown1
	$user .= _write_u32le(3);                     # unknown2 (per protocol spec)
	$user .= _write_u32le(0);                     # unknown3

	return $user;
}

sub _write_u32le {
	my ($value) = @_;
	return pack('V', $value);
}

sub _write_u16le {
	my ($value) = @_;
	return pack('v', $value);
}

1;
