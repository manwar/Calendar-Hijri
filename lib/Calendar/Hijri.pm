package Calendar::Hijri;

$Calendar::Hijri::VERSION = '0.09';

=head1 NAME

Calendar::Hijri - Interface to Islamic Calendar.

=head1 VERSION

Version 0.09

=cut

use strict; use warnings;
use Time::Local;
use Data::Dumper;
use Time::localtime;
use List::Util qw/min/;
use POSIX qw/floor ceil/;
use Date::Calc qw/Delta_Days Day_of_Week Add_Delta_Days/;

my $ISLAMIC_EPOCH   = 1948439.5;
my $GREGORIAN_EPOCH = 1721425.5;

my $MONTHS = [
    undef,
    q/Muharram/, q/Safar/   , q/Rabi' al-awwal/, q/Rabi' al-thani/, q/Jumada al-awwal/,  q/Jumada al-thani/,
    q/Rajab/   , q/Sha'aban/, q/Ramadan/       , q/Shawwal/       , q/Dhu al-Qi'dah/   , q/Dhu al-Hijjah/   ];

my $LEAP_YEAR_MOD  = [ 2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29 ];

sub new {
    my ($class, $yyyy, $mm, $dd) = @_;

    my $self  = {};
    bless $self, $class;

    if (defined($yyyy) && defined($mm) && defined($dd)) {
        _validate_date($yyyy, $mm, $dd)
    }
    else {
        ($yyyy, $mm, $dd) = $self->today();
    }

    $self->{yyyy} = $yyyy;
    $self->{mm}   = $mm;
    $self->{dd}   = $dd;

    return $self;
}

=head1 DESCRIPTION

Hijri Calendar begins with the migration from Mecca to Medina of Mohammad (pbuh),
the Prophet of Islam, an event  known  as the Hegira. The initials A.H.  before a
date mean "anno Hegirae" or "after Hegira". The  first  day  of the year is fixed
in the Quran as the first day of the month of Muharram.In 17 AH Umar I,the second
caliph, established the beginning of the era of the Hegira ( 1 Muharram 1 AH ) as
the date that is 16 July 622 CE in the Julian Calendar.

The years are lunar & consist of 12 lunar months. There is no intercalary period,
since the Quran ( Sura IX, verses 36,37 )  sets  the calendar year  at 12 months.
Because the year in the Hijri  calendar is shorter than a solar year, the  months
drift with respect to the seasons, in a cycle 32.50 years.

NOTE: The Hijri date produced by this module can have +1/-1 day error.

=head1 MONTHS

    +--------+-----------------+
    | Number | Name            |
    +--------+-----------------+
    |   1    | Muharram        |
    |   2    | Safar           |
    |   3    | Rabi' al-awwal  |
    |   4    | Rabi' al-thani  |
    |   5    | Jumada al-awwal |
    |   6    | Jumada al-thani |
    |   7    | Rajab           |
    |   8    | Sha'aban        |
    |   9    | Ramadan         |
    |  10    | Shawwal         |
    |  11    | Dhu al-Qi'dah   |
    |  12    | Dhu al-Hijjah   |
    +--------+-----------------+

=head1 METHODS

=head2 today()

Return today's date is Hijri Calendar as list in the format yyyy,mm,dd.

    use strict; use warnings;
    use Calendar::Hijri;

    my $calendar = Calendar::Hijri->new();
    my ($yyyy, $mm, $dd) = $calendar->today();
    print "Year [$yyyy] Month [$mm] Day [$dd]\n";

=cut

sub today {
    my ($self) = @_;

    my $today = localtime;

    return $self->from_gregorian($today->year+1900, $today->mon+1, $today->mday);
}

=head2 as_string()

Return Hijri date in human readable format.

    use strict; use warnings;
    use Calendar::Hijri;

    my $calendar = Calendar::Hijri->new(1432, 7, 27);
    print "Hijri date is " . $calendar->as_string() . "\n";

=cut

sub as_string {
    my ($self) = @_;

    return sprintf("%02d, %s %04d", $self->{dd}, $MONTHS->[$self->{mm}], $self->{yyyy});
}

=head2 is_leap_year()

Return 1 or 0 depending on whether the given year is a leap year or not in Hijri Calendar.

    use strict; use warnings;
    use Calendar::Hijri;

    my $calendar = Calendar::Hijri->new(1432, 7, 27);
    ($calendar->is_leap_year())
    ?
    (print "YES Leap Year\n")
    :
    (print "NO Leap Year\n");

=cut

sub is_leap_year {
    my ($self, $yyyy) = @_;

    $yyyy = $self->{yyyy} unless defined $yyyy;

    return unless defined $yyyy;

    my $mod = $yyyy%30;
    return 1 if grep/$mod/,@$LEAP_YEAR_MOD;
    return 0;
}

=head2 days_in_year()

Returns the number of days in the given year of Hijri Calendar.

    use strict; use warnings;
    use Calendar::Hijri;

    my $calendar = Calendar::Hijri->new(1432, 7, 27);
    print "Total number of days in year 1432: " . $calendar->days_in_year() . "\n";

=cut

sub days_in_year {
    my ($self, $yyyy) = @_;

    $yyyy = $self->{yyyy} unless defined $yyyy;

    return unless defined $yyyy;

    ($self->is_leap_year($yyyy))
    ?
    (return 355)
    :
    (return 354);
}

=head2 days_in_month()

Return number of days in the given year and month of Hijri Calendar.

    use strict; use warnings;
    use Calendar::Hijri;

    my $calendar = Calendar::Hijri->new(1432,7,26);
    print "Days is Rajab   1432: [" . $calendar->days_in_month() . "]\n";

    print "Days is Shawwal 1432: [" . $calendar->days_in_month(1432, 8) . "]\n";

=cut

sub days_in_month {
    my ($self, $yyyy, $mm) = @_;

    $mm = $self->{mm}     unless defined $mm;
    $yyyy = $self->{yyyy} unless defined $yyyy;

    return unless (defined($mm) && defined($yyyy));

    return 30 if (($mm%2 == 1) || (($mm == 12) && ($self->is_leap_year($yyyy))));
    return 29;
}

=head2 days_so_far()

Returns number of days before the 1st of given year and month of Hijri Calendar.

    use strict; use warnings;
    use Calendar::Hijri;

    my $calendar = Calendar::Hijri->new(1432, 7, 27);
    print "Days before 01 Rajab    1432: " . $calendar->days_so_far()        . "\n";
    print "Days before 01 Ramadaan 1432: " . $calendar->days_so_far(1432, 9) . "\n";

=cut

sub days_so_far {
    my ($self, $yyyy, $mm) = @_;

    $mm   = $self->{mm}   unless defined $mm;
    $yyyy = $self->{yyyy} unless defined $yyyy;
    return unless (defined($mm) && defined($yyyy));

    my $days = 0;
    foreach (1..$mm) {
        $days += $self->days_in_month($yyyy, $_);
    }

    return $days;
}

=head2 add_day()

Returns new date in Hijri Calendar after adding the given number of day(s) to the original date.

    my $calendar = Calendar::Hijri->new(1432, 7, 27);
    print "Hijri Date 1:" . $calendar->as_string() . "\n";
    $calendar->add_day(2);
    print "Hijri Date 2:" . $calendar->as_string() . "\n";

=cut

sub add_day {
    my ($self, $day, $dd, $mm, $yyyy) = @_;

    $dd   = $self->{dd}   unless defined $dd;
    $mm   = $self->{mm}   unless defined $mm;
    $yyyy = $self->{yyyy} unless defined $yyyy;

    return unless (defined($dd) && defined($mm) && defined($yyyy));

    foreach (1..$day) {
        ($dd, $mm, $yyyy) = _add_day($self->days_in_month($yyyy, $mm), $dd, $mm, $yyyy);
    }

    return ($dd, $mm, $yyyy);
}

=head2 get_calendar()

Return  Hijri  Calendar  for the given month and year. In case of missing  month  and year, it
would return current month Hijri Calendar.

    use strict; use warnings;
    use Calendar::Hijri;

    my $calendar = Calendar::Hijri->new(1432, 7, 27);
    print $calendar->get_calendar();

=cut

sub get_calendar {
    my ($self, $yyyy, $mm) = @_;

    $yyyy = $self->{yyyy} unless defined $yyyy;
    $mm   = $self->{mm}   unless defined $mm;

    my ($calendar, $start_index, $days);
    $calendar = sprintf("\n\t%s [%04d]\n", $MONTHS->[$mm], $yyyy);
    $calendar .= "\nSat  Sun  Mon  Tue  Wed  Thu  Fri\n";

    $start_index = $self->start_index($yyyy, $mm);
    $days = $self->days_in_month($yyyy, $mm);
    map { $calendar .= "     " } (1..$start_index);
    foreach (1 .. $days) {
        $calendar .= sprintf("%3d  ", $_);
        $calendar .= "\n" unless (($start_index+$_)%7);
    }

    return sprintf("%s\n\n", $calendar);
}

=head2 from_gregorian()

Converts given Gregorian date to Hijri date.

    use Calendar::Hijri;

    my $calendar = Calendar::Hijri->new();
    my ($yyyy, $mm, $dd) = $calendar->from_gregorian(2011, 3, 22);

=cut

sub from_gregorian {
    my ($self, $yyyy, $mm, $dd) = @_;

    return $self->from_julian(_gregorian_to_julian($yyyy, $mm, $dd));
}


=head2 to_gregorian()

Converts Hijri date to Gregorian date.

    use Calendar::Hijri;

    my $calendar = Calendar::Hijri->new();
    my ($yyyy, $mm, $dd) = $calendar->to_gregorian();

=cut

sub to_gregorian {
    my ($self, $yyyy, $mm, $dd) = @_;

    $yyyy = $self->{yyyy} unless defined $yyyy;
    $mm   = $self->{mm}   unless defined $mm;
    $dd   = $self->{dd}   unless defined $dd;

    return _julian_to_gregorian($self->to_julian($yyyy, $mm, $dd));
}

=head2 to_julian()

Converts Hijri date to Julian date.

    use Calendar::Hijri;

    my $calendar = Calendar::Hijri->new();
    my $julian   = $calendar->to_julian();

=cut

sub to_julian {
    my ($self, $yyyy, $mm, $dd) = @_;

    $yyyy = $self->{yyyy} unless defined $yyyy;
    $mm   = $self->{mm}   unless defined $mm;
    $dd   = $self->{dd}   unless defined $dd;

    return ($dd +
            ceil(29.5 * ($mm - 1)) +
            ($yyyy - 1) * 354 +
            floor((3 + (11 * $yyyy)) / 30) +
            $ISLAMIC_EPOCH) - 1;
}

sub from_julian {
    my ($self, $julian) = @_;

    $julian = floor($julian) + 0.5;
    my $yyyy = floor(((30 * ($julian - $ISLAMIC_EPOCH)) + 10646) / 10631);
    my $mm   = min(12, ceil(($julian - (29 + $self->to_julian($yyyy, 1, 1))) / 29.5) + 1);
    my $dd   = ($julian - $self->to_julian($yyyy, $mm, 1)) + 1;

    return ($yyyy, $mm, $dd);
}

sub start_index {
    my ($self, $yyyy, $mm) = @_;

    $yyyy = $self->{yyyy} unless defined $yyyy;
    $mm   = $self->{mm}   unless defined $mm;

    my ($g_y, $g_m, $g_d) = $self->to_gregorian($yyyy, 1, 1);
    my $dow = Day_of_Week($g_y, $g_m, $g_d);

    return $dow if $mm == 1;
    my $days = $self->days_so_far($yyyy, $mm-1);

    for (1..$days) {
        if ($dow != 6) {
            $dow++;
        }
        else {
            $dow = 0;
        }
    }

    return $dow
}

sub _gregorian_to_julian {
    my ($yyyy, $mm, $dd) = @_;

    return ($GREGORIAN_EPOCH - 1) +
           (365 * ($yyyy - 1)) +
           floor(($yyyy - 1) / 4) +
           (-floor(($yyyy - 1) / 100)) +
           floor(($yyyy - 1) / 400) +
           floor((((367 * $mm) - 362) / 12) +
           (($mm <= 2) ? 0 : (_is_leap($yyyy) ? -1 : -2)) +
           $dd);
}

sub _julian_to_gregorian {
    my ($julian) = @_;

    my $wjd        = floor($julian - 0.5) + 0.5;
    my $depoch     = $wjd - $GREGORIAN_EPOCH;
    my $quadricent = floor($depoch / 146097);
    my $dqc        = $depoch % 146097;
    my $cent       = floor($dqc / 36524);
    my $dcent      = $dqc % 36524;
    my $quad       = floor($dcent / 1461);
    my $dquad      = $dcent % 1461;
    my $yindex     = floor($dquad / 365);
    my $yyyy       = ($quadricent * 400) + ($cent * 100) + ($quad * 4) + $yindex;

    $yyyy++ unless (($cent == 4) || ($yindex == 4));

    my $yearday = $wjd - _gregorian_to_julian($yyyy, 1, 1);
    my $leapadj = (($wjd < _gregorian_to_julian($yyyy, 3, 1)) ? 0 : ((_is_leap($yyyy) ? 1 : 2)));
    my $mm      = floor(((($yearday + $leapadj) * 12) + 373) / 367);
    my $dd      = ($wjd - _gregorian_to_julian($yyyy, $mm, 1)) + 1;

    return ($yyyy, $mm, $dd);
}

sub _is_leap {
    my ($yyyy) = @_;

    return (($yyyy % 4) == 0) &&
            (!((($yyyy % 100) == 0) && (($yyyy % 400) != 0)));
}

# days: Total number of days in the given month mm.
sub _add_day {
    my ($days, $dd, $mm, $yyyy) = @_;

    return unless (defined($dd) && defined($mm) && defined($yyyy));

    $dd++;
    if ($dd >= 29)
    {
        if ($dd > $days)
        {
            $dd = 1;
            $mm++;
            if ($mm > 12)
            {
                $mm = 1;
                $yyyy++;
            }
        }
    }
    return ($dd, $mm, $yyyy);
}

sub _validate_date {
    my ($yyyy, $mm, $dd) = @_;

    die("ERROR: Invalid year [$yyyy].\n")
        unless (defined($yyyy) && ($yyyy =~ /^\d{4}$/) && ($yyyy > 0));
    die("ERROR: Invalid month [$mm].\n")
        unless (defined($mm) && ($mm =~ /^\d{1,2}$/) && ($mm >= 1) && ($mm <= 12));
    die("ERROR: Invalid day [$dd].\n")
        unless (defined($dd) && ($dd =~ /^\d{1,2}$/) && ($dd >= 1) && ($dd <= 30));
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/Manwar/Calendar-Hijri>

=head1 BUGS

Please report any bugs / feature requests to C<bug-calendar-hijri at rt.cpan.org>
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Calendar-Hijri>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Calendar::Hijri

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Calendar-Hijri>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Calendar-Hijri>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Calendar-Hijri>

=item * Search CPAN

L<http://search.cpan.org/dist/Calendar-Hijri/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2015 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Calendar::Hijri
