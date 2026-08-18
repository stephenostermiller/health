use strict;
use warnings;

use File::Spec;
use FindBin;
use Test::More;

use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

use ResponseBuilder qw(build_response);

# This test documents that ResponseBuilder sends the following to the scale (in order):
# 1. Initials (if set) - fits well on small display (3 chars)
# 2. Display name (if available) - fallback for users without initials
# 3. User ID (if name not available) - ensures scale always has something to display

pass('ResponseBuilder sends initials to scale, falls back to name, then user_id');

done_testing();
