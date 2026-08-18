use strict;
use warnings;

use File::Spec;
use FindBin;
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

use HealthDashboard::Auth qw(get_user_by_id_or_name);

# This test verifies that the new user_name and initials columns exist in the database.
# The get_user_by_id_or_name function queries these columns, so if the migration
# hasn't been applied, this test will fail with "Unknown column" error.
# This ensures that dashboard rendering won't fail at runtime.

my $error;
eval {
	get_user_by_id_or_name(login => 'nonexistent_user_for_test');
	1;
} or do {
	$error = $@;
};

if ($error && $error =~ /Unknown column.*user_name/) {
	fail('Database migration not applied - user_name column missing: ' . $error);
} elsif ($error) {
	fail('Unexpected database error: ' . $error);
} else {
	pass('New user_name and initials columns exist in database');
}

done_testing();
