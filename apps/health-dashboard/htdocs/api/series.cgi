#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../lib";

use HealthDashboard::App qw(render_series_response);
use HealthDashboard::Auth qw(get_user_id_from_cookie);

binmode(STDOUT);

my $cookie = _extract_auth_cookie();
my $user_id = get_user_id_from_cookie(cookie => $cookie);

unless (defined $user_id && length($user_id)) {
	print "Status: 401 Unauthorized\r\n";
	print "Content-Type: application/json\r\n";
	print "Content-Length: 30\r\n\r\n";
	print '{"error":"Not authenticated"}';
	exit;
}

my $response = render_series_response(
	query_string => ($ENV{QUERY_STRING} // ''),
	user_id => $user_id,
);

my $status = $response->{status} || 200;
my $status_text = $status == 200 ? 'OK' : 'Error';
print "Status: $status $status_text\r\n";
while (my ($name, $value) = splice(@{$response->{headers}}, 0, 2)) {
	print "$name: $value\r\n";
}
print "\r\n";
print $response->{body};

sub _extract_auth_cookie {
	my $cookie_header = $ENV{HTTP_COOKIE} // '';
	for my $cookie (split /;\s*/, $cookie_header) {
		my ($name, $value) = split /=/, $cookie, 2;
		return $value if $name eq 'auth';
	}
	return undef;
}
