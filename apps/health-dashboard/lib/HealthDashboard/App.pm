package HealthDashboard::App;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP;

use HealthDashboard::Metrics qw(default_metric metrics_for_client metric_definition);
use HealthDashboard::Queries qw(fetch_series_data);

our @EXPORT_OK = qw(render_dashboard_page render_series_response);

sub render_dashboard_page {
	my $config = JSON::PP->new->ascii->canonical->encode({
		defaultMetric => default_metric(),
		metrics => metrics_for_client(),
	});

	return <<"HTML";
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Health Dashboard</title>
  <link rel="stylesheet" href="static/dashboard.css">
</head>
<body>
  <div class="page">
    <section class="hero">
      <h1>Health dashboard</h1>
      <p>Explore imported health metrics from MySQL using the shared ETL fact and aggregate tables.</p>
    </section>

    <form id="controls" class="controls">
      <div class="control">
        <label for="metric">Metric</label>
        <select id="metric" name="metric"></select>
      </div>
      <div class="control">
        <label for="granularity">Granularity</label>
        <select id="granularity" name="granularity">
          <option value="raw">Raw</option>
          <option value="day" selected>Day</option>
          <option value="week">Week</option>
          <option value="month">Month</option>
          <option value="year">Year</option>
        </select>
      </div>
      <div class="control">
        <label for="start">Start</label>
        <input id="start" name="start" type="date">
      </div>
      <div class="control">
        <label for="end">End</label>
        <input id="end" name="end" type="date">
      </div>
      <div class="control">
        <label>&nbsp;</label>
        <button type="submit">Update chart</button>
      </div>
    </form>

    <section class="chart-panel">
      <div style="height: 420px;">
        <canvas id="health-chart"></canvas>
      </div>
      <div id="chart-status"></div>
    </section>

    <section class="summary-panel">
      <div id="summary" class="summary-grid"></div>
    </section>
  </div>

  <script>window.dashboardConfig = $config;</script>
  <script src="static/vendor/chart.umd.js"></script>
  <script src="static/dashboard.js"></script>
</body>
</html>
HTML
}

sub render_series_response {
	my (%args) = @_;
	my $params = _parse_query_string($args{query_string} // '');
	my $metric = $params->{metric} || default_metric();
	my $granularity = $params->{granularity} || 'day';
	my $definition = metric_definition($metric);

	if (!$definition) {
		return _json_response(400, { error => 'Unknown metric' });
	}

	my $result;
	eval {
		$result = fetch_series_data(
			metric => $metric,
			granularity => $granularity,
			start => $params->{start},
			end => $params->{end},
			definition => $definition,
		);
		1;
	} or do {
		my $error = $@ || 'Unknown query error';
		$error =~ s/\s+\z//;
		return _json_response(500, { error => $error });
	};

	return _json_response(200, $result);
}

sub _json_response {
	my ($status, $payload) = @_;
	my $body = JSON::PP->new->ascii->canonical->encode($payload);
	return {
		status => $status,
		headers => [
			'Content-Type', 'application/json; charset=utf-8',
			'Content-Length', length($body),
		],
		body => $body,
	};
}

sub _parse_query_string {
	my ($query_string) = @_;
	my %params;
	for my $pair (split /&/, $query_string) {
		next if $pair eq '';
		my ($key, $value) = split /=/, $pair, 2;
		$key = _percent_decode($key // '');
		$value = _percent_decode($value // '');
		$params{$key} = $value;
	}
	return \%params;
}

sub _percent_decode {
	my ($value) = @_;
	$value =~ tr/+/ /;
	$value =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
	return $value;
}

1;
