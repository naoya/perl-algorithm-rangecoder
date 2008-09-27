package Algorithm::RangeCoder;
use strict;
use warnings;
use base qw/Class::Accessor::Lvalue::Fast/;

use Carp;
use POSIX qw/floor/;
use Data::Integer qw/uint uint_madd uint_min uint_cmp uint_shl uint_shr/;

use Algorithm::RangeCoder::Util;

__PACKAGE__->mk_accessors(qw/out R L D buffer carryN start freq cumfreq/);

use constant INIT_RANGE => 0xFFFFFFFF;
use constant MASK       => 0xFFFFFFFF;
use constant TOP        => uint_shl(1, 24);
use constant UCHAR_MAX  => 0x100;

sub init {
    my ($self, $binref) = @_;

    $$binref ||= '';

    $self->out     = $binref;
    $self->buffer  = 0;
    $self->carryN  = 0;
    $self->start   = 1;

    $self->R       = INIT_RANGE;
    $self->L       = 0;
    $self->D       = 0;
}

sub encode {
    my ($self, $str) = @_;
    $self->init;

    for my $c ( unpack('C*', $str) ) {
        $self->_encode(
            $self->cumfreq->[$c],
            $self->cumfreq->[$c + 1],
            $self->cumfreq->[-1]
        );
    }
    $self->_finish;

    return ${$self->out};
}

## FIXME: floating point arithmetic
sub div ($$) {
    my ($x, $y) = @_;
    floor($x/$y);
}

sub _encode {
    my ($self, $low, $high, $total) = @_;
    my $r = div($self->R, $total);

    if ($high < $total) {
        $self->R = $r * ($high - $low);
    } else {
        $self->R -= $r * $low;
    }

    my $newL = uint_madd($self->L, ($r * $low));

    if ( uint_cmp($newL, $self->L) == -1 ) {
        $self->buffer++;

        for (; $self->carryN > 0; $self->carryN--) {
            put($self->buffer, $self->out);
            $self->buffer = 0;
        }
    }
    $self->L = $newL;

    while ( uint_cmp($self->R, TOP) == -1 ) {
        my $newBuffer = uint_shr($self->L, 24) & 0xFF;

        if ($self->start) {
            $self->buffer = $newBuffer;
            $self->start  = undef;
        }
        elsif ($newBuffer == 0xFF) {
            $self->carryN++;
        }
        else {
            put($self->buffer, $self->out);
            for (; $self->carryN != 0; $self->carryN--) {
                put(0xFF, $self->out);
            }
            $self->buffer = ($newBuffer & 0xFF);
        }

        $self->L = uint_shl($self->L, 8);
        $self->R = uint_shl($self->R, 8);
    }
}


sub _finish {
    my $self = shift;

    if ($self->buffer) {
        put($self->buffer, $self->out);
    }

    for (; $self->carryN != 0; $self->carryN--) {
        put(0xff, $self->out);
    }

    for (my $i = 0; $i < 4; $i++) {
        put(uint_shr($self->L, 24), $self->out);
        $self->L = uint_shl($self->L, 8);
    }
}

sub decode {
    my ($self, $bin) = @_;
    $self->init(\$bin);

    for (my $i = 0; $i < 4; $i++) {
        $self->D = uint_shl($self->D, 8) | get($self->out);
    }

    my $out;
    for (my $i = 0; $i < $self->cumfreq->[-1]; $i++) {
        $out .= chr ( $self->_decode );
    }
    return $out;
}

sub _decode {
    my $self = shift;
    my $total = $self->cumfreq->[-1];

    my $r   = div($self->R, $total);
    my $pos = uint_min( $total - 1, div($self->D, $r) );

    my $code = search_code( $pos, $self->cumfreq );
    my $low  = $self->cumfreq->[ $code ];
    my $high = $self->cumfreq->[ $code + 1];

    $self->D -= $r * $low;
    if ($high != $total) {
        $self->R = $r * ($high - $low);
    }
    else {
        $self->R -= $r * $low;
    }

    while ($self->R < TOP) {
        $self->R = uint_shl($self->R, 8);
        $self->D = uint_shl($self->D, 8) | get($self->out);
    }

    return $code;
}

sub search_code {
    my ($value, $cum) = @_;
    use integer;

    my $i = 0;
    my $j = UCHAR_MAX;

    while ($i < $j) {
        my $k = ($i + $j) / 2;
        if ($cum->[ $k + 1 ] <= $value) {
            $i = $k + 1;
        } else {
            $j = $k;
        }
    }

    return $i;
}

1;
