package Collector;

use strict;
use warnings;

use Exporter 'import';
use POSIX qw(strftime);

use Protocol qw(parse_request);
use Collector::DB qw(connect_db);
use ResponseBuilder qw(build_response);

our @EXPORT_OK = qw(handle_request capture_request_body build_metric_facts calculate_body_fat_percent);

sub handle_request {
	my (%args) = @_;
	my $env = $args{env} || {};
	my $body = defined $args{body} ? $args{body} : '';

	my $parsed = parse_request($body, ignore_registered_users => 0);
	my $facts = build_metric_facts($parsed);

	# Extract user_id from the scale's request
	die "No readings in request\n" unless @{$parsed->{readings}};
	my $user_id = $parsed->{readings}[0]{user_id};

	my $dbh = connect_db();
	$dbh->begin_work;

	eval {
		_persist_facts($dbh, $facts);
		_refresh_aggregates($dbh, $facts);
		$dbh->commit;
		1;
	} or do {
		$dbh->rollback;
		die $@;
	};

	my $response_body = build_response(
		dbh => $dbh,
		user_id => $user_id,
	);

	$dbh->disconnect;

	return {
		status => 200,
		headers => [
			'Content-Type' => 'application/octet-stream',
			'Content-Length' => length($response_body),
		],
		body => $response_body,
	};
}

sub capture_request_body {
	my ($env) = @_;
	my $content_length = $env->{CONTENT_LENGTH};
	my $body = '';
	binmode(STDIN);

	if (defined $content_length && $content_length =~ /^\d+$/) {
		my $read = read(STDIN, $body, $content_length);
		die "Failed to read request body\n" if !defined $read;
		return $body;
	}

	local $/;
	$body = <STDIN>;
	return defined $body ? $body : '';
}

sub build_metric_facts {
	my ($parsed) = @_;
	my @facts;
	my $mac = $parsed->{mac};

	for my $i (0 .. scalar(@{$parsed->{readings}}) - 1) {
		my $reading = $parsed->{readings}[$i];
		my $timestamp = _format_timestamp_iso($reading->{date});

		push @facts, {
			metric => 'weight',
			unit => 'lb',
			user_id => $reading->{user_id},
			value => $reading->{weight_lbs},
			timestamp => $timestamp,
			data_source => 'fitbit-aria',
		};
		
		my $body_fat_percent = calculate_body_fat_percent($reading);
		if (defined $body_fat_percent) {
			push @facts, {
				metric => 'body_fat',
				unit => '%',
				user_id => $reading->{user_id},
				value => $body_fat_percent,
				timestamp => $timestamp,
				data_source => 'fitbit-aria',
			};
		}
	}

	return \@facts;
}

sub _persist_facts {
	my ($dbh, $facts) = @_;

	for my $fact (@$facts) {
		$dbh->do(
			'INSERT INTO metric_fact (timestamp, metric, unit, user_id, value, data_source, loaded_at)
			 VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
			 ON DUPLICATE KEY UPDATE unit=VALUES(unit), value=VALUES(value), data_source=VALUES(data_source), loaded_at=CURRENT_TIMESTAMP',
			undef,
			$fact->{timestamp},
			$fact->{metric},
			$fact->{unit},
			$fact->{user_id},
			$fact->{value},
			$fact->{data_source},
		);
	}
}

sub _refresh_aggregates {
	my ($dbh, $facts) = @_;

	my %by_day;
	my %by_week;
	my %by_month;
	my %by_year;

	for my $fact (@$facts) {
		my $day = substr($fact->{timestamp}, 0, 10);
		my $week = _get_week_start($fact->{timestamp});
		my $month = substr($fact->{timestamp}, 0, 7) . '-01';
		my $year = substr($fact->{timestamp}, 0, 4);

		my $day_key = join('|', $fact->{user_id}, $fact->{metric}, $day);
		my $week_key = join('|', $fact->{user_id}, $fact->{metric}, $week);
		my $month_key = join('|', $fact->{user_id}, $fact->{metric}, $month);
		my $year_key = join('|', $fact->{user_id}, $fact->{metric}, $year);

		push @{$by_day{$day_key}}, { value => $fact->{value}, unit => $fact->{unit} };
		push @{$by_week{$week_key}}, { value => $fact->{value}, unit => $fact->{unit} };
		push @{$by_month{$month_key}}, { value => $fact->{value}, unit => $fact->{unit} };
		push @{$by_year{$year_key}}, { value => $fact->{value}, unit => $fact->{unit} };
	}

	for my $key (keys %by_day) {
		my ($user_id, $metric, $day) = split /\|/, $key;
		_upsert_aggregate($dbh, 'metric_aggregate_day', 'day_date', $day, $metric, $user_id, $by_day{$key});
	}

	for my $key (keys %by_week) {
		my ($user_id, $metric, $week) = split /\|/, $key;
		_upsert_aggregate($dbh, 'metric_aggregate_week', 'week_start_date', $week, $metric, $user_id, $by_week{$key});
	}

	for my $key (keys %by_month) {
		my ($user_id, $metric, $month) = split /\|/, $key;
		_upsert_aggregate($dbh, 'metric_aggregate_month', 'month_start_date', $month, $metric, $user_id, $by_month{$key});
	}

	for my $key (keys %by_year) {
		my ($user_id, $metric, $year) = split /\|/, $key;
		_upsert_aggregate($dbh, 'metric_aggregate_year', 'year_number', $year, $metric, $user_id, $by_year{$key});
	}
}

sub _upsert_aggregate {
	my ($dbh, $table, $date_col, $date_val, $metric, $user_id, $values) = @_;

	my @numbers = map { $_->{value} } @$values;
	my $unit = @$values ? $values->[0]{unit} : '';

	my @sorted = sort { $a <=> $b } @numbers;
	my $min = $sorted[0];
	my $max = $sorted[-1];
	my $sum = 0;
	for my $v (@numbers) { $sum += $v; }
	my $count = scalar @numbers;
	my $mean = $sum / $count;

	$dbh->do(
		"INSERT INTO $table ($date_col, metric, unit, user_id, \`min\`, \`max\`, \`mean\`, \`sum\`, \`count\`, refreshed_at)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
		 ON DUPLICATE KEY UPDATE \`min\`=LEAST(\`min\`, VALUES(\`min\`)), \`max\`=GREATEST(\`max\`, VALUES(\`max\`)), \`mean\`=(\`sum\`+VALUES(\`sum\`))/((\`count\`+VALUES(\`count\`))), \`sum\`=\`sum\`+VALUES(\`sum\`), \`count\`=\`count\`+VALUES(\`count\`), refreshed_at=VALUES(refreshed_at)",
		undef,
		$date_val, $metric, $unit, $user_id, $min, $max, $mean, $sum, $count,
	);
}

sub _get_week_start {
	my ($timestamp) = @_;
	my @parts = split /-|:| /, $timestamp;
	my ($year, $month, $day) = @parts[0..2];
	use Time::Local;
	my $epoch = timelocal(0, 0, 0, $day, $month - 1, $year - 1900);
	my @gmtime = gmtime($epoch);
	my $weekday = $gmtime[6];
	my $days_back = $weekday;
	my $week_epoch = $epoch - ($days_back * 86400);
	@gmtime = gmtime($week_epoch);
	return sprintf('%04d-%02d-%02d', $gmtime[5] + 1900, $gmtime[4] + 1, $gmtime[3]);
}

sub _format_timestamp_iso {
	my ($epoch) = @_;
	my @gmtime = gmtime($epoch);
	return sprintf(
		'%04d-%02d-%02d %02d:%02d:%02d',
		$gmtime[5] + 1900,
		$gmtime[4] + 1,
		$gmtime[3],
		$gmtime[2],
		$gmtime[1],
		$gmtime[0],
	);
}

sub calculate_body_fat_percent {
	my ($reading) = @_;

	my $fat_1 = $reading->{body_fat_1};
	my $fat_2 = $reading->{body_fat_2};

	return undef if !defined $fat_1 || !defined $fat_2;
	return undef if $fat_1 == 0 && $fat_2 == 0;

	my $fat_1_percent = $fat_1 / 1000;
	my $fat_2_percent = $fat_2 / 1000;

	return ($fat_1_percent + $fat_2_percent) / 2;
}

1;
