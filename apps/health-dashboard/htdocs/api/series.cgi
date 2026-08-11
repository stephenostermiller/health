#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../lib";

use HealthDashboard::App qw(render_series_response);

binmode(STDOUT);

my $response = render_series_response(
	query_string => ($ENV{QUERY_STRING} // ''),
);

my $status = $response->{status} || 200;
my $status_text = $status == 200 ? 'OK' : 'Error';
print "Status: $status $status_text\r\n";
while (my ($name, $value) = splice(@{$response->{headers}}, 0, 2)) {
	print "$name: $value\r\n";
}
print "\r\n";
print $response->{body};
