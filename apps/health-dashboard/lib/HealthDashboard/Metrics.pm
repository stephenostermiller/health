package HealthDashboard::Metrics;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(default_metric metric_definition metrics_for_client);

my @METRICS = (
	{
		metric => 'weight',
		label => 'Weight',
		unit => 'pounds',
		color => '#355c7d',
		default_granularity => 'day',
	},
	{
		metric => 'body_fat',
		label => 'Body fat',
		unit => 'percent',
		color => '#c06c84',
		default_granularity => 'day',
	},
);

sub default_metric {
	return $METRICS[0]{metric};
}

sub metric_definition {
	my ($name) = @_;
	for my $metric (@METRICS) {
		return $metric if $metric->{metric} eq $name;
	}
	return;
}

sub metrics_for_client {
	return [map {
		{
			metric => $_->{metric},
			label => $_->{label},
			unit => $_->{unit},
			defaultGranularity => $_->{default_granularity},
		}
	} @METRICS];
}

1;
