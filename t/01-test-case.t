#!perl

use Test::More tests => 3;

use strict; use warnings;
use Calendar::Hijri;

my ($calendar);

eval { $calendar = Calendar::Hijri->new(-1432, 1, 1); };
like($@, qr/ERROR: Invalid year \[\-1432\]./);

eval { $calendar = Calendar::Hijri->new(1432, 13, 1); };
like($@, qr/ERROR: Invalid month \[13\]./);

eval { $calendar = Calendar::Hijri->new(1432, 12, 31); };
like($@, qr/ERROR: Invalid day \[31\]./);