package UserAuth;

use strict;
use warnings;

use Exporter 'import';
use Crypt::Bcrypt qw(bcrypt bcrypt_check);

our @EXPORT_OK = qw(
	hash_password
	verify_password
);

# Hash a password using bcrypt with random salt
# Format: $2b$12$... (bcrypt RFC2307 format)
sub hash_password {
	my ($password) = @_;

	return undef unless defined $password && length($password);

	my $salt = _read_random_bytes(16);
	my $hash = bcrypt($password, '2b', 12, $salt);
	return $hash;
}

# Verify a password against a hash
# Uses bcrypt_check which is timing-safe internally
# Returns true if password matches, false otherwise
sub verify_password {
	my ($password, $stored_hash) = @_;

	return 0 unless defined $password && defined $stored_hash;

	return bcrypt_check($password, $stored_hash);
}

sub _read_random_bytes {
	my ($count) = @_;
	my $bytes;
	open(my $fh, '<:raw', '/dev/urandom') or die "Cannot open /dev/urandom: $!\n";
	read($fh, $bytes, $count) or die "Cannot read from /dev/urandom: $!\n";
	close($fh);
	return $bytes;
}

1;
