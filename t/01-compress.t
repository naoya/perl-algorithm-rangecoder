use Test::Base;

use Algorithm::RangeCoder;
use constant UCHAR_MAX => 0x100;

my (@freq, @cum);
sub update_frequency ($) {
    my $str = shift;

    for (my $i = 0; $i < UCHAR_MAX; $i++) {
        $freq[$i] = 0;
    }

    for my $c ( unpack('C*', $str) ) {
        $freq[$c]++;
    }

    @cum = (0);
    for (my $i = 0; $i < UCHAR_MAX; $i++) {
        $cum[$i + 1] = $cum[$i] + $freq[$i];
    }
}

sub encode ($) {
    my $str = shift;

    update_frequency($str);

    my $rc = Algorithm::RangeCoder->new;
    $rc->freq    = \@freq;
    $rc->cumfreq = \@cum;
    $rc->encode($str);
}

sub decode ($) {
    my $bin = shift;

    my $rc = Algorithm::RangeCoder->new;
    $rc->freq    = \@freq;
    $rc->cumfreq = \@cum;

    $rc->decode($bin);
}

filters { in => [qw/encode decode/] };

__END__
===
--- in
abc
--- out
abc
===
--- in
cabbababaasazzzzzzzzzzzzzzzzzzzadfas@@@
--- out
cabbababaasazzzzzzzzzzzzzzzzzzzadfas@@@
===
--- in
#!/usr/bin/perl
use Perl6::Say;

say 'Hello, World!';
--- out
#!/usr/bin/perl
use Perl6::Say;

say 'Hello, World!';
===
--- in
いろはにほへとちりぬるを
--- out
いろはにほへとちりぬるを
===
--- in
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad
minim veniam, quis nostrud exercitation ullamco laboris nisi ut
aliquip ex ea commodo consequat. Duis aute irure dolor in
reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
culpa qui officia deserunt mollit anim id est laborum.
--- out
Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do
eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad
minim veniam, quis nostrud exercitation ullamco laboris nisi ut
aliquip ex ea commodo consequat. Duis aute irure dolor in
reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
culpa qui officia deserunt mollit anim id est laborum.

