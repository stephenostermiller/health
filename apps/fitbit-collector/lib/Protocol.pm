package Protocol;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP ();

use CRC qw(crc16_xmodem);

our @EXPORT_OK = qw(parse_request);

my $HEADER_SIZE = 46;
my $ITEM_SIZE = 32;
my $CRC_SIZE = 2;

sub parse_request {
	my ($payload, %opts) = @_;
	$payload //= '';

	my $ignore_registered_users = $opts{ignore_registered_users} ? 1 : 0;
	my $minimum_size = $HEADER_SIZE + $CRC_SIZE;
	die "Payload too short: expected at least $minimum_size bytes\n" if length($payload) < $minimum_size;

	my $header = substr($payload, 0, $HEADER_SIZE);
	my $data_without_crc = substr($payload, 0, length($payload) - $CRC_SIZE);
	my $provided_crc = _read_u16le(substr($payload, length($payload) - $CRC_SIZE, $CRC_SIZE));
	my $computed_crc = crc16_xmodem($data_without_crc);

	my $records_and_remainder = substr($payload, $HEADER_SIZE, length($payload) - $HEADER_SIZE - $CRC_SIZE);
	my $record_count = int(length($records_and_remainder) / $ITEM_SIZE);
	my $remainder = substr($records_and_remainder, $record_count * $ITEM_SIZE);

	my @records;
	for my $index (0 .. $record_count - 1) {
		my $offset = $index * $ITEM_SIZE;
		my $chunk = substr($records_and_remainder, $offset, $ITEM_SIZE);
		my $item = _parse_record($chunk);
		next if $ignore_registered_users && $item->{user_id} > 0;
		push @records, $item;
	}

	my $ret = {
		date => _read_u32le(substr($header, 38, 4)),
		item_count => _read_u32le(substr($header, 42, 4)),
		battery => _read_u32le(substr($header, 4, 4)),
		protocol => _read_u32le(substr($header, 0, 4)),
		firmware => _read_u32le(substr($header, 30, 4)),
		mac => _format_mac(substr($header, 8, 5)),
		readings => \@records,
		checksum => {
			provided => $provided_crc,
			computed => $computed_crc,
			valid => $provided_crc == $computed_crc ? JSON::PP::true() : JSON::PP::false(),
		},
		raw_record_count => $record_count,
	};
	$ret->{friendly_date} = _format_timestamp($ret->{date});

	my @warnings;
	push @warnings, sprintf('Item count field %d does not match parsed records %d', $ret->{item_count}, $record_count)
		if $ret->{item_count} != $record_count;
	push @warnings, sprintf('Trailing %d bytes before CRC were ignored', length($remainder)) if length($remainder) > 0;
	push @warnings, 'CRC16/XModem checksum mismatch' if $provided_crc != $computed_crc;
	$ret->{warnings} = \@warnings if @warnings;
	$ret->{trailing_bytes_hex} = unpack('H*', $remainder) if length($remainder) > 0;

	return $ret;
}

sub _parse_record {
	my ($chunk) = @_;
	die "Record too short: expected $ITEM_SIZE bytes\n" if length($chunk) != $ITEM_SIZE;

	my $raw_weight = _read_u32le(substr($chunk, 8, 4));
	my $date = _read_u32le(substr($chunk, 12, 4));

	return {
		user_id => _read_u32le(substr($chunk, 16, 4)),
		weight_kg => $raw_weight / 1000,
		weight_st => $raw_weight / 6350.293,
		weight_lbs => $raw_weight / 453.6,
		date => $date,
		friendly_date => _format_timestamp($date),
		impedance => _read_u32le(substr($chunk, 4, 4)),
		body_fat_1 => _read_u32le(substr($chunk, 20, 4)),
		covariance => _read_u32le(substr($chunk, 24, 4)),
		body_fat_2 => _read_u32le(substr($chunk, 28, 4)),
	};
}

sub _read_u32le {
	my ($bytes) = @_;
	die "Expected 4 bytes for uint32\n" if length($bytes) != 4;
	return unpack('V', $bytes);
}

sub _read_u16le {
	my ($bytes) = @_;
	die "Expected 2 bytes for uint16\n" if length($bytes) != 2;
	return unpack('v', $bytes);
}

sub _format_mac {
	my ($bytes) = @_;
	return join(':', map { sprintf('%02x', $_) } unpack('C*', $bytes));
}

sub _format_timestamp {
	my ($epoch) = @_;
	my @gmtime = gmtime($epoch);
	my @weekday = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
	my @month = qw(January February March April May June July August September October November December);
	my @suffix = qw(th st nd rd th th th th th th);
	my $day = $gmtime[3];
	my $suffix = ($day % 100 >= 11 && $day % 100 <= 13) ? 'th' : $suffix[$day % 10];
	my $hour = $gmtime[2] % 12;
	$hour = 12 if $hour == 0;
	my $minute = sprintf('%02d', $gmtime[1]);
	my $ampm = $gmtime[2] >= 12 ? 'pm' : 'am';

	return sprintf(
		'%s %d%s %s %d, %d:%s%s UTC',
		$weekday[$gmtime[6]],
		$day,
		$suffix,
		$month[$gmtime[4]],
		$gmtime[5] + 1900,
		$hour,
		$minute,
		$ampm,
	);
}

1;