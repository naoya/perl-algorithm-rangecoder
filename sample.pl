#!/usr/bin/env perl
use strict;
use warnings;

use FindBin::libs;
use Perl6::Say;

use constant UCHAR_MAX => 0x100;

use Algorithm::RangeCoder;

$SIG{__DIE__} = \&Carp::confess;

my $str = shift or die "usage: $0 <string>";

my @char = unpack('C*', $str);

my @freq;
for (my $i = 0; $i < UCHAR_MAX; $i++) {
    $freq[$i] = 0;
}

for my $c (@char) {
    $freq[$c]++;
}

my @cum = (0);
for (my $i = 0; $i < UCHAR_MAX; $i++) {
    $cum[$i + 1] = $cum[$i] + $freq[$i];
}

my $rc = Algorithm::RangeCoder->new;
$rc->freq    = \@freq;
$rc->cumfreq = \@cum;
$rc->debug++;

say $rc->decode( $rc->encode($str) )

