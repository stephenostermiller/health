package HealthDashboard::Auth;

use strict;
use warnings;

use Exporter 'import';
use Digest::HMAC_SHA1 qw(hmac_sha1_hex);
use MIME::Base64 qw(encode_base64 decode_base64);

use HealthDashboard::DB qw(connect_db);
use UserAuth qw(hash_password verify_password);

our @EXPORT_OK = qw(
	authenticate_user
	get_user_id_from_cookie
	create_auth_cookie
	user_exists
	set_user_password
	get_user_by_id_or_name
	update_user_field
	get_secret_key
);

# Authenticate user by name/id and password
# Returns user_id on success, undef on failure
sub authenticate_user {
	my (%args) = @_;
	my $login = $args{login};
	my $password = $args{password};

	return undef unless defined $login && defined $password;

	my $dbh = connect_db();
	my $user = $dbh->selectrow_hashref(
		'SELECT id, password_hash FROM `user` WHERE id = ? OR name = ? LIMIT 1',
		undef,
		$login,
		$login
	);
	$dbh->disconnect;

	return undef unless $user;
	return undef unless $user->{password_hash};
	return undef unless verify_password($password, $user->{password_hash});

	return $user->{id};
}

# Extract and verify user_id from signed cookie
sub get_user_id_from_cookie {
	my (%args) = @_;
	my $cookie = $args{cookie};

	return undef unless defined $cookie && length($cookie);

	my ($user_id, $signature) = split /\./, $cookie, 2;
	return undef unless defined $user_id && defined $signature;

	my $expected_sig = hmac_sha1_hex($user_id, get_secret_key());
	return undef unless $signature eq $expected_sig;

	return $user_id;
}

# Create a signed auth cookie containing user_id
# Format: user_id.hmac_signature
sub create_auth_cookie {
	my (%args) = @_;
	my $user_id = $args{user_id};

	return undef unless defined $user_id;

	my $signature = hmac_sha1_hex($user_id, get_secret_key());
	return "$user_id.$signature";
}

# Check if user exists
sub user_exists {
	my (%args) = @_;
	my $login = $args{login};

	return 0 unless defined $login;

	my $dbh = connect_db();
	my $count = $dbh->selectrow_array(
		'SELECT COUNT(*) FROM `user` WHERE id = ? OR name = ? LIMIT 1',
		undef,
		$login,
		$login
	);
	$dbh->disconnect;

	return $count > 0;
}

# Set password for a user
sub set_user_password {
	my (%args) = @_;
	my $user_id = $args{user_id};
	my $password = $args{password};

	return 0 unless defined $user_id && defined $password && length($password);

	my $hash = hash_password($password);
	return 0 unless $hash;

	my $dbh = connect_db();
	my $result = $dbh->do(
		'UPDATE `user` SET password_hash = ? WHERE id = ?',
		undef,
		$hash,
		$user_id
	);
	$dbh->disconnect;

	return $result > 0;
}

# Get user by id or name
sub get_user_by_id_or_name {
	my (%args) = @_;
	my $login = $args{login};

	return undef unless defined $login;

	my $dbh = connect_db();
	my $user = $dbh->selectrow_hashref(
		'SELECT id, name, height_mm FROM `user` WHERE id = ? OR name = ? LIMIT 1',
		undef,
		$login,
		$login
	);
	$dbh->disconnect;

	return $user;
}

# Update a user field (name or height_mm)
sub update_user_field {
	my (%args) = @_;
	my $user_id = $args{user_id};
	my $field = $args{field};
	my $value = $args{value};

	return 0 unless defined $user_id && defined $field && defined $value;

	my %allowed_fields = (
		name => 1,
		height_mm => 1,
	);
	return 0 unless $allowed_fields{$field};

	# Validate field-specific constraints
	if ($field eq 'name') {
		return 0 if !$value || length($value) > 20 || length($value) == 0;
	} elsif ($field eq 'height_mm') {
		return 0 if $value < 0 || $value > 2500000;  # Reasonable height limits in mm
	}

	my $dbh = connect_db();
	my $result = $dbh->do(
		"UPDATE \`user\` SET $field = ? WHERE id = ?",
		undef,
		$value,
		$user_id
	);
	$dbh->disconnect;

	return $result > 0;
}

# Get or generate the secret key for signing cookies
# In production, this should come from a config file or environment variable
sub get_secret_key {
	return $ENV{DASHBOARD_SECRET_KEY} || 'change-me-in-production';
}

1;
