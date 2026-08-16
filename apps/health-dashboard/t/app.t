use strict;
use warnings;

use File::Spec;
use FindBin;
use JSON::PP;
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

use HealthDashboard::App qw(render_dashboard_page render_series_response);
use HealthDashboard::Metrics qw(default_metric metric_definition);
use HealthDashboard::Queries qw(validate_range granularity_policy supported_granularities);

my $html = render_dashboard_page();
unlike($html, qr/value="raw"/, 'raw option removed');

my $bad = render_series_response(query_string => 'metric=not_real&granularity=day');
is($bad->{status}, 400, 'unknown metric is rejected');

my $bad_granularity = render_series_response(query_string => 'metric=weight&granularity=raw');
is($bad_granularity->{status}, 400, 'raw granularity is rejected');

my $bad_aggregation = render_series_response(query_string => 'metric=weight&granularity=day&aggregation=sum');
is($bad_aggregation->{status}, 400, 'unsupported aggregation is rejected');

my $bad_range = render_series_response(query_string => 'metric=weight&granularity=day&start=2024-01-01&end=2026-12-31');
is($bad_range->{status}, 400, 'day granularity with large range is rejected');

is(default_metric(), 'weight', 'default metric is weight');
ok(metric_definition('body_fat'), 'body fat metric is defined');

# Granularity policy tests
my $policy = granularity_policy();
is_deeply($policy->{year}, {}, 'year has no max span');
is($policy->{day}{maxSpanDays}, 730, 'day has 730-day max span');
is($policy->{week}{maxSpanDays}, 1456, 'week has 1456-day max span');
is($policy->{month}{maxSpanMonths}, 288, 'month has 288-month max span');

# Supported granularities test
my @supported = supported_granularities();
is(scalar @supported, 4, 'exactly 4 supported granularities');
ok(grep { $_ eq 'day' } @supported, 'day is supported');
ok(!grep { $_ eq 'raw' } @supported, 'raw is not supported');

# validate_range tests
is(validate_range(granularity => 'day', start => '2026-01-01', end => '2026-01-15'), undef, 'day with 14-day range is valid');
ok(validate_range(granularity => 'day', start => '2023-01-01', end => '2026-12-31'), 'day with large range is invalid');
is(validate_range(granularity => 'month', start => '', end => ''), undef, 'empty start/end bypasses validation');
ok(validate_range(granularity => 'day', start => '2026-01-15', end => '2026-01-01'), 'start > end is invalid');

# Month arithmetic tests (unexported but callable fully-qualified)
is(HealthDashboard::Queries::_subtract_months('2026-03-31', 1), '2026-02-28', 'subtract 1 month from March 31 clips to Feb 28');
is(HealthDashboard::Queries::_subtract_months('2024-03-31', 1), '2024-02-29', 'subtract 1 month from March 31 of leap year clips to Feb 29');
is(HealthDashboard::Queries::_subtract_months('2026-01-15', 13), '2024-12-15', 'subtract 13 months underflows year correctly');

done_testing();
