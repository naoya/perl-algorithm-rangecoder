#!/usr/local/bin/perl
use strict;
use warnings;
use FindBin::libs;

use constant UCHAR_MAX => 255;

use Algorithm::RangeCoder;

my $text = shift or die "usage: $0 <text>";

## 記号の出現頻度を求める
my @freq;
for (my $i = 0; $i < UCHAR_MAX; $i++) {
    $freq[$i] = 0;
}

for my $c ( unpack('C*', $text) ) {
    $freq[$c]++;
}

## 記号の累積出現頻度を求める
my @cum = (0);
for (my $i = 0; $i < UCHAR_MAX; $i++) {
    $cum[$i + 1] = $cum[$i] + $freq[$i];
}

my $rc = Algorithm::RangeCoder->new;
$rc->freq    = \@freq;
$rc->cumfreq = \@cum;

$rc->encode($text);

