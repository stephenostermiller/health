package HealthDataEtl::DB;

use strict;
use warnings;

use Exporter 'import';
use File::Spec;
use File::Basename qw(dirname);
use Cwd qw(abs_path);

our @EXPORT_OK = qw(connect_db load_facts load_user refresh_aggregates);

sub connect_db {
	require DBI;

	_load_env_file();

	my $database = $ENV{MYSQL_DATABASE} || die "MYSQL_DATABASE is required\n";
	my $host = $ENV{MYSQL_HOST} || 'localhost';
	my $port = $ENV{MYSQL_PORT} || 3306;
	my $user = $ENV{MYSQL_USER} || die "MYSQL_USER is required\n";
	my $password = $ENV{MYSQL_PWD} // '';

	my $dsn = "DBI:mysql:database=$database;host=$host;port=$port;charset=utf8mb4";
	my $dbh = DBI->connect(
		$dsn,
		$user,
		$password,
		{
			RaiseError => 1,
			PrintError => 0,
			AutoCommit => 1,
			mysql_enable_utf8mb4 => 1,
		},
	) or die "Unable to connect to MySQL\n";

	return $dbh;
}

sub load_facts {
	my ($dbh, $facts, $user_id) = @_;

	$dbh->begin_work;
	eval {
		for my $fact (@$facts) {
			$dbh->do(
				'INSERT INTO metric_fact (timestamp, metric, unit, user_id, value, data_source, loaded_at)
				 VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
				 ON DUPLICATE KEY UPDATE unit=VALUES(unit), value=VALUES(value),
					 data_source=VALUES(data_source), loaded_at=CURRENT_TIMESTAMP',
				undef,
				@{$fact}{qw(timestamp metric unit user_id value data_source)},
			);
		}
		$dbh->commit;
		1;
	} or do {
		$dbh->rollback;
		die $@;
	};
}

sub load_user {
	my ($dbh, $user) = @_;

	$dbh->begin_work;
	eval {
		$dbh->do(
			'INSERT INTO `user` (id, name, birthdate, gender, user_name, initials)
			 VALUES (?, ?, ?, ?, ?, ?)
			 ON DUPLICATE KEY UPDATE name=VALUES(name), birthdate=VALUES(birthdate),
				 gender=VALUES(gender), user_name=VALUES(user_name), initials=VALUES(initials)',
			undef,
			@{$user}{qw(id name birthdate gender user_name initials)},
		);
		$dbh->commit;
		1;
	} or do {
		$dbh->rollback;
		die $@;
	};
}

sub refresh_aggregates {
	my ($dbh) = @_;
	$dbh->do('CALL refresh_metric_aggregates()');
}

sub _load_env_file {
	return if $ENV{MYSQL_USER};

	# Build path then normalize to resolve .. components
	my $env_file = abs_path(File::Spec->catfile(abs_path(__FILE__), '..', '..', '..', '..', '..', '.env'));

	return unless -f $env_file;

	open(my $fh, '<', $env_file) or return;
	while (my $line = <$fh>) {
		chomp $line;
		next if $line =~ /^\s*#/ || $line =~ /^\s*$/;
		if ($line =~ /^\s*(\w+)\s*=\s*(.*)$/) {
			my ($key, $value) = ($1, $2);
			$value =~ s/^['"]|['"]$//g;
			$ENV{$key} = $value unless exists $ENV{$key};
		}
	}
	close($fh);
}

1;
