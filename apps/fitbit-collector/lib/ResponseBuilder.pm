package ResponseBuilder;

use strict;
use warnings;

use Exporter 'import';
use POSIX qw(time);
use CRC qw(crc16_xmodem);

our @EXPORT_OK = qw(build_response);

sub build_response {
	my (%opts) = @_;

	my $current_timestamp = time();
	my $units = 0;
	my $status = 0x32;
	my $user_count = 1;

	my $body = '';
	$body .= _write_u32le($current_timestamp);
	$body .= chr($units);
	$body .= chr($status);
	$body .= chr(0x01);
	$body .= _write_u32le($user_count);

	my $user = _build_user();
	$body .= $user;

	$body .= _write_u32le(0x03);
	$body .= _write_u32le(0);

	my $crc = crc16_xmodem($body);
	my $envelope = $body . _write_u16le($crc) . chr(0x66) . chr(0x00);

	return $envelope;
}

sub _build_user {
	my $user_id = 45016898;
	my $name = "User";
	my $age = 30;
	my $gender = 0x34;
	my $height_mm = 1800;

	my $user = '';
	$user .= _write_u32le($user_id);
	$user .= pack('C16', 0) x 1;
	$user .= pack('A20', $name);
	$user .= _write_u32le(0);
	$user .= _write_u32le(100000000);
	$user .= _write_u32le($age);
	$user .= chr($gender);
	$user .= _write_u32le($height_mm);
	$user .= _write_u32le(0);
	$user .= _write_u32le(0);
	$user .= _write_u32le(0);
	$user .= _write_u32le(0);
	$user .= _write_u32le(0);
	$user .= _write_u32le(0);

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
