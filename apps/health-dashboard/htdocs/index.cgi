#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use HealthDashboard::App qw(render_dashboard_page);

binmode(STDOUT);

my $body = render_dashboard_page();

print "Status: 200 OK\r\n";
print "Content-Type: text/html; charset=utf-8\r\n";
print 'Content-Length: ' . length($body) . "\r\n\r\n";
print $body;
