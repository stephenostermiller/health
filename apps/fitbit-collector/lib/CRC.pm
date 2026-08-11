package CRC;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(crc16_xmodem);

sub crc16_xmodem {
	my ($buffer) = @_;
	my $result = 0x0000;

	for my $byte (unpack('C*', $buffer // '')) {
		$result ^= ($byte << 8);
		for (1 .. 8) {
			$result <<= 1;
			$result ^= 0x1021 if ($result & 0x10000);
			$result &= 0xFFFF;
		}
	}

	return $result;
}

1;