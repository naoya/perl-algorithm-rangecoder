package Algorithm::RangeCoder;
use strict;
use warnings;
use Exporter::Lite;

our @EXPORT = qw/put get bitstr/;
our @EXPORT_OK = @EXPORT;

sub bitstr ($) {
    my $n = shift;
    unpack('B*', pack('N', $n));
}

sub put ($$) {
    my ($c, $r_buf) = @_;
    $$r_buf = join '', $$r_buf, chr( $c & 0xff );
}

sub get ($) {
    my ($r_buf) = @_;
    my $c = unpack('C', $$r_buf);
    substr($$r_buf, 0, 1) = '';
    return $c;
}

1;
