package HealthDashboard::Queries;

use strict;
use warnings;

use Exporter 'import';

use HealthDashboard::DB qw(connect_db primary_user_id);

our @EXPORT_OK = qw(fetch_series_data);

my %AGGREGATES = (
	day => {
		table => 'metric_aggregate_day',
		period_column => 'day_date',
	},
	week => {
		table => 'metric_aggregate_week',
		period_column => 'week_start_date',
	},
	month => {
		table => 'metric_aggregate_month',
		period_column => 'month_start_date',
	},
	year => {
		table => 'metric_aggregate_year',
		period_column => 'year_number',
	},
);

sub fetch_series_data {
	my (%args) = @_;
	my $metric = $args{metric} or die "metric is required\n";
	my $granularity = $args{granularity} || 'day';
	my $definition = $args{definition} || {};

	if ($granularity eq 'raw') {
		return _fetch_raw_series(%args);
	}

	my $aggregate = $AGGREGATES{$granularity} or die "Unsupported granularity\n";
	my $dbh = connect_db();
	my $user_id = primary_user_id();
	my @bind = ($metric, $user_id);
	my @where = ('metric = ?', 'user_id = ?');

	if (defined $args{start} && $args{start} ne '') {
		push @where, "$aggregate->{period_column} >= ?";
		push @bind, $args{start};
	}
	if (defined $args{end} && $args{end} ne '') {
		push @where, "$aggregate->{period_column} <= ?";
		push @bind, $args{end};
	}

	my $sql = sprintf(
		'SELECT %s AS label, `mean`, `min`, `max`, `count` FROM %s WHERE %s ORDER BY %s',
		$aggregate->{period_column},
		$aggregate->{table},
		join(' AND ', @where),
		$aggregate->{period_column},
	);

	my $rows = $dbh->selectall_arrayref($sql, { Slice => {} }, @bind);
	$dbh->disconnect();

	return {
		metric => $metric,
		label => $definition->{label} || $metric,
		granularity => $granularity,
		unit => $definition->{unit} || '',
		labels => [map { $_->{label} } @$rows],
		datasets => [
			{
				label => ($definition->{label} || $metric) . ' mean',
				data => [map { 0 + $_->{mean} } @$rows],
				borderColor => $definition->{color} || '#355c7d',
				backgroundColor => 'rgba(53, 92, 125, 0.15)',
				tension => 0.2,
			},
		],
	};
}

sub _fetch_raw_series {
	my (%args) = @_;
	my $metric = $args{metric};
	my $definition = $args{definition} || {};
	my $dbh = connect_db();
	my $user_id = primary_user_id();
	my @bind = ($metric, $user_id);
	my @where = ('metric = ?', 'user_id = ?');

	if (defined $args{start} && $args{start} ne '') {
		push @where, '`timestamp` >= ?';
		push @bind, $args{start} . ' 00:00:00';
	}
	if (defined $args{end} && $args{end} ne '') {
		push @where, '`timestamp` <= ?';
		push @bind, $args{end} . ' 23:59:59';
	}

	my $sql = 'SELECT `timestamp` AS label, value FROM metric_fact WHERE ' . join(' AND ', @where) . ' ORDER BY `timestamp` LIMIT 2000';
	my $rows = $dbh->selectall_arrayref($sql, { Slice => {} }, @bind);
	$dbh->disconnect();

	return {
		metric => $metric,
		label => $definition->{label} || $metric,
		granularity => 'raw',
		unit => $definition->{unit} || '',
		labels => [map { $_->{label} } @$rows],
		datasets => [
			{
				label => $definition->{label} || $metric,
				data => [map { 0 + $_->{value} } @$rows],
				borderColor => $definition->{color} || '#355c7d',
				backgroundColor => 'rgba(53, 92, 125, 0.15)',
				tension => 0.2,
			},
		],
	};
}

1;
