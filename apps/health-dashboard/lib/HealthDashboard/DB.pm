package HealthDashboard::DB;

use strict;
use warnings;

use Exporter 'import';
use File::Spec;
use File::Basename qw(dirname);
use Cwd qw(abs_path);

our @EXPORT_OK = qw(connect_db primary_user_id);

sub connect_db {
	require DBI;

	_load_env_file();

	my $database = $ENV{MYSQL_DATABASE} || 'health';
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

sub primary_user_id {
	return $ENV{PRIMARY_USER_ID} || 0;
}

1;
