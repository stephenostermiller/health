use strict;
use warnings;

use File::Spec;
use FindBin;
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

use HealthDashboard::App qw(render_dashboard_page render_series_response);
use HealthDashboard::Metrics qw(default_metric metric_definition);

my $html = render_dashboard_page();
like($html, qr/Health dashboard/, 'dashboard page renders heading');
like($html, qr/window\.dashboardConfig/, 'dashboard page embeds bootstrap config');

my $bad = render_series_response(query_string => 'metric=not_real&granularity=day');
is($bad->{status}, 400, 'unknown metric is rejected');

is(default_metric(), 'weight', 'default metric is weight');
ok(metric_definition('body_fat'), 'body fat metric is defined');

done_testing();
