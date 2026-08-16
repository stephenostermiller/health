#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../lib";

use JSON::PP;
use HealthDashboard::Auth qw(authenticate_user create_auth_cookie set_user_password get_user_by_id_or_name user_exists update_user_field get_user_id_from_cookie create_user user_has_data);

binmode(STDOUT);
binmode(STDIN);

my $request_body = do { local $/; <STDIN> };
my $data = eval { JSON::PP->new->decode($request_body) } // {};
my $action = $data->{action};

my $response;

sub _extract_auth_cookie {
	my $cookie_header = $ENV{HTTP_COOKIE} // '';
	for my $cookie (split /;\s*/, $cookie_header) {
		my ($name, $value) = split /=/, $cookie, 2;
		return $value if $name eq 'auth';
	}
	return undef;
}

eval {
	if ($action eq 'login') {
		my $login = $data->{login};
		my $password = $data->{password};

		if (!defined $login || $login eq '' || !defined $password || $password eq '') {
			$response = { error => 'Login and password are required' };
		} else {
			my $user = get_user_by_id_or_name(login => $login);

			if (!$user) {
				# User doesn't exist - create if they have data
				if (user_has_data(user_id => $login)) {
					if (create_user(user_id => $login)) {
						if (set_user_password(user_id => $login, password => $password)) {
							my $cookie = create_auth_cookie(user_id => $login);
							$response = { success => 1, cookie => $cookie };
						} else {
							$response = { needsPassword => 1, user_id => $login };
						}
					} else {
						$response = { error => 'Failed to create user' };
					}
				} else {
					$response = { error => 'User not found' };
				}
			} elsif (!$user->{password_hash}) {
				# User exists but has no password
				if (set_user_password(user_id => $user->{id}, password => $password)) {
					my $cookie = create_auth_cookie(user_id => $user->{id});
					$response = { success => 1, cookie => $cookie };
				} else {
					$response = { needsPassword => 1, user_id => $user->{id} };
				}
			} else {
				# User exists and has a password - authenticate
				my $user_id = authenticate_user(login => $login, password => $password);
				if (defined $user_id && length($user_id)) {
					my $cookie = create_auth_cookie(user_id => $user_id);
					$response = { success => 1, cookie => $cookie };
				} else {
					$response = { error => 'Invalid password' };
				}
			}
		}
	} elsif ($action eq 'set_password') {
		my $login = $data->{login};
		my $password = $data->{password};

		if (!defined $login || $login eq '' || !defined $password || $password eq '') {
			$response = { error => 'Login and password are required' };
		} elsif (!user_exists(login => $login)) {
			$response = { error => 'User not found' };
		} else {
			my $user = get_user_by_id_or_name(login => $login);
			if (set_user_password(user_id => $user->{id}, password => $password)) {
				$response = { success => 1 };
			} else {
				$response = { error => 'Failed to set password' };
			}
		}
	} elsif ($action eq 'update_user') {
		my $cookie = _extract_auth_cookie();
		my $user_id = get_user_id_from_cookie(cookie => $cookie);
		my $field = $data->{field};
		my $value = $data->{value};

		if (!$user_id) {
			$response = { error => 'Not authenticated' };
		} elsif (!$field || !defined $value) {
			$response = { error => 'Field and value are required' };
		} else {
			if (update_user_field(user_id => $user_id, field => $field, value => $value)) {
				$response = { success => 1 };
			} else {
				$response = { error => 'Failed to update user field' };
			}
		}
	} else {
		$response = { error => 'Unknown action' };
	}
	1;
} or do {
	my $error = $@ || 'Unknown error';
	$error =~ s/\s+\z//;
	$response = { error => $error };
};

my $body = JSON::PP->new->encode($response);
print "Status: 200 OK\r\n";
print "Content-Type: application/json\r\n";
print 'Content-Length: ' . length($body) . "\r\n\r\n";
print $body;
