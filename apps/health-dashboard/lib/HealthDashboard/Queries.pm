package HealthDashboard::Queries;

use strict;
use warnings;

use Exporter 'import';
use JSON::PP;
use Time::Local qw(timegm);

use HealthDashboard::DB qw(connect_db primary_user_id);

our @EXPORT_OK = qw(fetch_series_data validate_range granularity_policy supported_granularities);

my %AGGREGATES = (
	day => {
		table => 'metric_aggregate_day',
		period_column => 'day_date',
		period_type => 'date',
		default_span_days => 90,
		max_span_days => 180,
	},
	week => {
		table => 'metric_aggregate_week',
		period_column => 'week_start_date',
		period_type => 'date',
		default_span_days => 364,
		max_span_days => 728,
	},
	month => {
		table => 'metric_aggregate_month',
		period_column => 'month_start_date',
		period_type => 'date',
		default_span_months => 36,
		max_span_months => 144,
	},
	year => {
		table => 'metric_aggregate_year',
		period_column => 'year_number',
		period_type => 'year',
	},
);

sub fetch_series_data {
	my (%args) = @_;
	my $metric = $args{metric} or die "metric is required\n";
	my $granularity = $args{granularity} || 'day';
	my $aggregation = $args{aggregation} || 'mean';
	my $definition = $args{definition} || {};

	my $aggregate = $AGGREGATES{$granularity} or die "Unsupported granularity\n";
	my $dbh = connect_db();
	my $user_id = primary_user_id();

	my $available = _available_range($dbh, $aggregate, $metric, $user_id);
	my ($start, $end) = _resolve_start_end($aggregate, $available, $args{start}, $args{end});

	my @bind = ($metric, $user_id);
	my @where = ('metric = ?', 'user_id = ?');

	if (defined $start && $start ne '') {
		push @where, "$aggregate->{period_column} >= ?";
		push @bind, _period_bind_value($aggregate, $start);
	}
	if (defined $end && $end ne '') {
		push @where, "$aggregate->{period_column} <= ?";
		push @bind, _period_bind_value($aggregate, $end);
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

	my %aggregation_labels = (
		mean => 'average',
		min => 'minimum',
		max => 'maximum',
	);

	my $false = JSON::PP::false;
	my @datasets;
	if ($aggregation eq 'range') {
		@datasets = (
			{
				label => ($definition->{label} || $metric) . ' minimum',
				data => [map { 0 + $_->{min} } @$rows],
				borderColor => 'rgba(53, 92, 125, 0)',
				backgroundColor => 'rgba(53, 92, 125, 0.2)',
				borderWidth => 0,
				fill => $false,
				tension => 0.2,
				pointRadius => 0,
			},
			{
				label => ($definition->{label} || $metric) . ' maximum',
				data => [map { 0 + $_->{max} } @$rows],
				borderColor => 'rgba(53, 92, 125, 0)',
				backgroundColor => 'rgba(53, 92, 125, 0.2)',
				borderWidth => 0,
				fill => '-1',
				tension => 0.2,
				pointRadius => 0,
			},
			{
				label => ($definition->{label} || $metric) . ' average',
				data => [map { 0 + $_->{mean} } @$rows],
				borderColor => $definition->{color} || '#355c7d',
				backgroundColor => 'rgba(53, 92, 125, 0)',
				borderWidth => 2,
				fill => $false,
				tension => 0.2,
			},
		);
	} else {
		@datasets = (
			{
				label => ($definition->{label} || $metric) . ' ' . $aggregation_labels{$aggregation},
				data => [map { 0 + $_->{$aggregation} } @$rows],
				borderColor => $definition->{color} || '#355c7d',
				backgroundColor => 'rgba(53, 92, 125, 0.15)',
				tension => 0.2,
			},
		);
	}

	return {
		metric => $metric,
		label => $definition->{label} || $metric,
		granularity => $granularity,
		aggregation => $aggregation,
		unit => $definition->{unit} || '',
		range => {
			start => $start,
			end => $end,
			availableMin => $available->{min},
			availableMax => $available->{max},
		},
		labels => [map { $_->{label} } @$rows],
		datasets => \@datasets,
	};
}

sub supported_granularities {
	return sort keys %AGGREGATES;
}

sub granularity_policy {
	my %policy;
	for my $g (keys %AGGREGATES) {
		my $agg = $AGGREGATES{$g};
		my %entry;
		$entry{maxSpanDays} = $agg->{max_span_days} if $agg->{max_span_days};
		$entry{maxSpanMonths} = $agg->{max_span_months} if $agg->{max_span_months};
		$policy{$g} = \%entry;
	}
	return \%policy;
}

sub validate_range {
	my (%args) = @_;
	my $granularity = $args{granularity} || 'day';
	my ($start, $end) = @args{qw(start end)};

	return undef if !defined $start || $start eq '' || !defined $end || $end eq '';

	my $aggregate = $AGGREGATES{$granularity};
	return undef unless $aggregate;

	return 'Start date must be on or before end date' if $start gt $end;

	if (_exceeds_max_span($aggregate, $start, $end)) {
		my $limit;
		if ($aggregate->{max_span_days}) {
			$limit = "$aggregate->{max_span_days} days";
		} elsif ($aggregate->{max_span_months}) {
			$limit = "$aggregate->{max_span_months} months";
		}
		return "Selected range exceeds the maximum span of $limit for $granularity granularity" if $limit;
	}

	return undef;
}

sub _available_range {
	my ($dbh, $aggregate, $metric, $user_id) = @_;
	my $sql = sprintf(
		'SELECT MIN(%s) AS lo, MAX(%s) AS hi FROM %s WHERE metric = ? AND user_id = ?',
		$aggregate->{period_column},
		$aggregate->{period_column},
		$aggregate->{table},
	);
	my ($lo, $hi) = $dbh->selectrow_array($sql, undef, $metric, $user_id);
	return { min => undef, max => undef } if !defined $lo || !defined $hi;
	if ($aggregate->{period_type} eq 'year') {
		return { min => "$lo-01-01", max => "$hi-12-31" };
	}
	return { min => $lo, max => $hi };
}

sub _resolve_start_end {
	my ($aggregate, $available, $start, $end) = @_;
	my $has_explicit = defined $start && $start ne '' && defined $end && $end ne '';
	return ($start, $end) if $has_explicit;
	return (undef, undef) if !defined $available->{max};
	return ($available->{min}, $available->{max}) if $aggregate->{period_type} eq 'year';

	my $end_default = $available->{max};
	my $start_default;
	if ($aggregate->{default_span_days}) {
		$start_default = _add_days($end_default, -$aggregate->{default_span_days});
	} else {
		$start_default = _subtract_months($end_default, $aggregate->{default_span_months});
	}
	$start_default = $available->{min} if $available->{min} gt $start_default;
	return ($start_default, $end_default);
}

sub _period_bind_value {
	my ($aggregate, $value) = @_;
	return _year_of($value) if $aggregate->{period_type} eq 'year';
	return $value;
}

sub _year_of {
	my ($d) = @_;
	return $1 if $d =~ /^(\d{4})/;
	return $d;
}

sub _exceeds_max_span {
	my ($aggregate, $start, $end) = @_;
	return 0 if !$aggregate->{max_span_days} && !$aggregate->{max_span_months};
	if ($aggregate->{max_span_days}) {
		return (_epoch_for_date($end) - _epoch_for_date($start)) / 86400 > $aggregate->{max_span_days};
	}
	return $start lt _subtract_months($end, $aggregate->{max_span_months});
}

sub _epoch_for_date {
	my ($ymd) = @_;
	my ($y, $m, $d) = $ymd =~ /^(\d{4})-(\d{2})-(\d{2})/;
	return timegm(0, 0, 0, $d, $m - 1, $y);
}

sub _date_for_epoch {
	my ($epoch) = @_;
	my (undef, undef, undef, $day, $mon, $year) = gmtime($epoch);
	return sprintf('%04d-%02d-%02d', $year + 1900, $mon + 1, $day);
}

sub _add_days {
	my ($ymd, $delta) = @_;
	return _date_for_epoch(_epoch_for_date($ymd) + $delta * 86400);
}

sub _subtract_months {
	my ($ymd, $n) = @_;
	my ($y, $m, $d) = $ymd =~ /^(\d{4})-(\d{2})-(\d{2})/;
	$m -= $n;
	while ($m < 1) { $m += 12; $y--; }
	my $last_day = _days_in_month($y, $m);
	$d = $last_day if $d > $last_day;
	return sprintf('%04d-%02d-%02d', $y, $m, $d);
}

sub _days_in_month {
	my ($y, $m) = @_;
	my @days = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
	return 29 if $m == 2 && (($y % 4 == 0 && $y % 100 != 0) || $y % 400 == 0);
	return $days[$m - 1];
}

1;
