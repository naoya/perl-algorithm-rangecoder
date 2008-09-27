#!/usr/bin/env perl
use strict;
use warnings;

use FindBin::libs;
use Perl6::Say;
use Algorithm::RangeCoder;

use constant UCHAR_MAX => 0x100;

# my $str = shift or die "usage: $0 <string>";
my $str = <<EOF;
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad
minim veniam, quis nostrud exercitation ullamco laboris nisi ut
aliquip ex ea commodo consequat. Duis aute irure dolor in
reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
culpa qui officia deserunt mollit anim id est laborum.
EOF

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
# $rc->debug++;

my $bin = $rc->encode($str);

say "origin:  ", $str;
say "decoded: ", $rc->decode( $bin );

my $rate = length($bin) / length($str);

say sprintf "origin: %d bytes", length $str;
say sprintf "encoded: %d bytes (%.1f%%)", length $bin, $rate * 100;
