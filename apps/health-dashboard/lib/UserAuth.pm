package UserAuth;

use strict;
use warnings;

use Exporter 'import';
use Digest::SHA qw(sha256_hex);

our @EXPORT_OK = qw(
	hash_password
	verify_password
);

# Hash a password using SHA256 with a salt
# Format: sha256$salt$hash ($ separated for parsing)
sub hash_password {
	my ($password) = @_;

	return undef unless defined $password && length($password);

	my $salt = _generate_salt();
	my $hash = sha256_hex($salt . $password);
	return "sha256\$$salt\$$hash";
}

# Verify a password against a hash
# Returns true if password matches, false otherwise
sub verify_password {
	my ($password, $stored_hash) = @_;

	return 0 unless defined $password && defined $stored_hash;

	my ($method, $salt, $hash) = split /\$/, $stored_hash, 3;
	return 0 unless $method && $salt && $hash;

	my $computed_hash = sha256_hex($salt . $password);
	return $computed_hash eq $hash;
}

sub _generate_salt {
	my @chars = ('a'..'z', 'A'..'Z', '0'..'9');
	my $salt = '';
	for (1..16) {
		$salt .= $chars[rand @chars];
	}
	return $salt;
}

1;
