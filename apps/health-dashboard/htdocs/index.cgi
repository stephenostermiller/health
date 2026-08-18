#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use HealthDashboard::App qw(render_dashboard_page);

binmode(STDOUT);

my $cookie = _extract_auth_cookie();
my $response = render_dashboard_page(cookie => $cookie);

my $status = $response->{status} || 200;
my $status_text = $status == 200 ? 'OK' : 'Error';
my $body = $response->{body};
my $headers = $response->{headers} || [];

print "Status: $status $status_text\r\n";
print "Content-Type: text/html; charset=utf-8\r\n";
print 'Content-Length: ' . length($body) . "\r\n";
while (my ($name, $value) = splice(@{$headers}, 0, 2)) {
	print "$name: $value\r\n";
}
print "\r\n";
print $body;

sub _extract_auth_cookie {
	my $cookie_header = $ENV{HTTP_COOKIE} // '';
	for my $cookie (split /;\s*/, $cookie_header) {
		my ($name, $value) = split /=/, $cookie, 2;
		return $value if $name eq 'auth';
	}
	return undef;
}
