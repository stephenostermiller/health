#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use HealthDashboard::App qw(render_dashboard_page);

binmode(STDOUT);

my $cookie = _extract_auth_cookie();
my $body = render_dashboard_page(cookie => $cookie);

print "Status: 200 OK\r\n";
print "Content-Type: text/html; charset=utf-8\r\n";
print 'Content-Length: ' . length($body) . "\r\n\r\n";
print $body;

sub _extract_auth_cookie {
	my $cookie_header = $ENV{HTTP_COOKIE} // '';
	for my $cookie (split /;\s*/, $cookie_header) {
		my ($name, $value) = split /=/, $cookie, 2;
		return $value if $name eq 'auth';
	}
	return undef;
}
