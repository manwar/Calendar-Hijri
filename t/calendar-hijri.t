#!perl

use 5.006;
use Test::More tests => 2;
use strict; use warnings;
use Calendar::Hijri;

eval { Calendar::Hijri->new({ year => -1432, month => 1 }); };
like($@, qr/ERROR: Invalid year \[\-1432\]./);

eval { Calendar::Hijri->new({ year => 1432, month => 13 }); };
like($@, qr/ERROR: Invalid month \[13\]./);
