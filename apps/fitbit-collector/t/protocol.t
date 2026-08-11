use strict;
use warnings;

use File::Path qw(remove_tree);
use File::Spec;
use FindBin;
use JSON::PP;
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

use CRC qw(crc16_xmodem);
use Collector qw(build_metric_facts);
use Protocol qw(parse_request);

my $fixtures = File::Spec->catdir($FindBin::Bin, 'fixtures');
my $payload = _slurp(File::Spec->catfile($fixtures, 'request_data.bin'));
my $expected = JSON::PP->new->decode(_slurp(File::Spec->catfile($fixtures, 'request_data.json')));

my $parsed = parse_request($payload, ignore_registered_users => 0);
is_deeply($parsed, $expected, 'fixture payload parses as expected');
is($parsed->{raw_record_count}, 2, 'fixture payload contains two complete records');
ok(!exists $parsed->{warnings}, 'fixture payload parses without warnings');

my $guest_only = parse_request($payload, ignore_registered_users => 1);
is(scalar @{$guest_only->{readings}}, 1, 'registered users can be excluded');
is($guest_only->{readings}[0]{user_id}, 0, 'guest reading is retained');

my $bad_crc_payload = substr($payload, 0, length($payload) - 2) . pack('v', 0x1234);
my $bad_crc = parse_request($bad_crc_payload, ignore_registered_users => 0);
ok(!$bad_crc->{checksum}{valid}, 'CRC mismatch is detected');
like(join(' ', @{$bad_crc->{warnings} || []}), qr/CRC16\/XModem checksum mismatch/, 'CRC mismatch warning is recorded');

eval { parse_request(substr($payload, 0, 20)); 1 };
like($@, qr/Payload too short/, 'short payloads are rejected');

my $facts = build_metric_facts($expected);
is(scalar(@$facts), 10, 'collector generates 5 metrics per 2 readings');

my @weight_facts = grep { $_->{metric} eq 'weight' } @$facts;
is(scalar(@weight_facts), 2, 'weight facts for both readings');
is($weight_facts[0]->{value}, 155.4, 'guest reading weight in pounds');
is($weight_facts[1]->{value}, 179.1, 'registered reading weight in pounds');

is($weight_facts[0]->{user_id}, 0, 'guest reading user_id');
is($weight_facts[1]->{user_id}, 42, 'registered reading user_id');

is($weight_facts[0]->{source_row}, 0, 'first reading is source_row 0');
is($weight_facts[1]->{source_row}, 1, 'second reading is source_row 1');

is($weight_facts[0]->{source_file}, 'aria:aa:bb:cc:dd:ee', 'source_file uses MAC address');
like($weight_facts[0]->{timestamp}, qr/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/, 'timestamp is ISO format');

my @impedance_facts = grep { $_->{metric} eq 'body_composition.impedance' } @$facts;
is($impedance_facts[0]->{value}, 501, 'impedance value preserved');
is($impedance_facts[1]->{value}, 650, 'second impedance value');

my @body_fat_1 = grep { $_->{metric} eq 'body_composition.body_fat_1' } @$facts;
is($body_fat_1[0]->{value}, 1234, 'body_fat_1 value preserved');

my @body_fat_2 = grep { $_->{metric} eq 'body_composition.body_fat_2' } @$facts;
is($body_fat_2[0]->{value}, 91011, 'body_fat_2 value preserved');

my @covariance = grep { $_->{metric} eq 'body_composition.covariance' } @$facts;
is($covariance[0]->{value}, 5678, 'covariance value preserved');

done_testing();

sub _slurp {
	my ($path) = @_;
	open(my $fh, '<:raw', $path) or die "Unable to read $path: $!\n";
	local $/;
	my $content = <$fh>;
	close($fh) or die "Unable to close $path: $!\n";
	return $content;
}
