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
	{
		metric => 'body_composition.impedance',
		label => 'Impedance',
		unit => 'ohms',
		color => '#f59e0b',
		default_granularity => 'day',
	},
	{
		metric => 'body_composition.body_fat_1',
		label => 'Body fat 1',
		unit => 'raw',
		color => '#ec4899',
		default_granularity => 'day',
	},
	{
		metric => 'body_composition.body_fat_2',
		label => 'Body fat 2',
		unit => 'raw',
		color => '#8b5cf6',
		default_granularity => 'day',
	},
	{
		metric => 'body_composition.covariance',
		label => 'Covariance',
		unit => 'raw',
		color => '#06b6d4',
		default_granularity => 'day',
	},
	{
		metric => 'daily_resting_heart_rate',
		label => 'Resting heart rate',
		unit => 'beats_per_minute',
		color => '#6c5b7b',
		default_granularity => 'day',
	},
	{
		metric => 'daily_oxygen_saturation.average',
		label => 'Daily oxygen saturation',
		unit => 'percent',
		color => '#2a9d8f',
		default_granularity => 'day',
	},
	{
		metric => 'daily_vo2_max.cardio_fitness',
		label => 'Daily VO2 max',
		unit => 'score',
		color => '#d97706',
		default_granularity => 'month',
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
