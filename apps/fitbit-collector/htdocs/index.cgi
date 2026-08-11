#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Collector qw(capture_request_body handle_request);

binmode(STDOUT);

my %env = %ENV;

my $body;
my $response;

eval {
	$body = capture_request_body(\%env);
	$response = handle_request(
		env => \%env,
		body => $body,
	);
	1;
} or do {
	my $error = $@ || "Unknown error\n";
	my $message = "Collector error: $error";
	print "Status: 500 Internal Server Error\r\n";
	print "Content-Type: text/plain\r\n";
	print 'Content-Length: ' . length($message) . "\r\n\r\n";
	print $message;
	exit 0;
};

my $status = $response->{status} || 200;
my $status_text = $status == 200 ? 'OK' : 'Error';
print "Status: $status $status_text\r\n";

my $headers = $response->{headers} || [];
while (my ($name, $value) = splice(@{$headers}, 0, 2)) {
	print "$name: $value\r\n";
}

print "\r\n";
print $response->{body} // '';
