#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use JSON::PP;

use Protocol qw(parse_request);

my $path = shift @ARGV or die "Call with a request_data file as an argument.\n";

open(my $fh, '<:raw', $path) or die "Unable to read $path: $!\n";
local $/;
my $payload = <$fh>;
close($fh) or die "Unable to close $path: $!\n";

my $parsed = parse_request($payload, ignore_registered_users => 0);
print JSON::PP->new->ascii->pretty->canonical->encode($parsed);
