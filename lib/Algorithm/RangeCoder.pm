package Algorithm::RangeCoder;
use strict;
use warnings;
use base qw/Class::Accessor::Lvalue::Fast/;

use Carp;
use POSIX qw/floor/;
use List::Util qw/min/;
use Params::Validate qw/validate_pos SCALARREF/;
use Perl6::Say;
use Data::Integer qw/uint uint_madd/;

use Algorithm::RangeCoder::Util;

__PACKAGE__->mk_accessors(qw/out R L D buffer carryN start debug counter freq cumfreq/);

use constant INIT_RANGE => 0xFFFFFFFF;
use constant MASK       => 0xFFFFFFFF;
use constant TOP        => 1 << 24;
use constant UCHAR_MAX  => 0x100;

say "MAX_RANGE: ", bitstr( INIT_RANGE );
say "MASK:      ", bitstr( MASK );

sub init {
    my ($self, $binref) = @_;

    $$binref ||= '';

    $self->out     = $binref;
    $self->buffer  = 0;
    $self->carryN  = 0;
    $self->start   = 1;
    $self->counter = 0;

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

sub _encode {
    my ($self, $low, $high, $total) = @_;

    if ($self->debug) {
        say sprintf "L(%d): %s", $self->counter, bitstr($self->L);
        say sprintf "R(%d): %s", $self->counter, bitstr($self->R);
    }

    my $r = floor( $self->R / $total );

    if ($self->debug) {
        say sprintf "r(%d): %s", $self->counter, bitstr($r);
    }

    ## R の更新
    if ($high < $total) {
        $self->R = $r * ($high - $low);
    } else {
        $self->R -= $r * $low;
    }

    my $newL = uint_madd($self->L, ($r * $low));
    if ($newL > 0xffffffff) {
        if ($self->debug) {
            warn 'L overflow, treat newL as overflowed bits';
        }
        $newL = $newL >> 31;
    }
    $newL &= MASK;

    ## 怪しい?
    if ($self->debug) {
        say 'L:  ', bitstr($self->L), " ", $self->L;
        say 'nL: ', bitstr($newL),    " ", $newL;
    }

    if ($newL < $self->L) {
        warn 'treat overflowed bits';
        $self->buffer++;
        for (; $self->carryN > 0; $self->carryN--) {
            put($self->buffer, $self->out);
            $self->buffer = 0;
        }
    }
    $self->L = $newL;

    while ($self->R < TOP) {
        my $newBuffer = ($self->L >> 24) & 0xFF;
        if ($self->debug) {
            say "newBuffer: ", bitstr($newBuffer);
        }

        if ($self->start) {
            $self->buffer = $newBuffer;
            $self->start  = undef;
        }
        elsif (($newBuffer & 0xFF) == 0xFF) {
            $self->carryN++;
        }
        else {
            put($self->buffer, $self->out);
            for (; $self->carryN != 0; $self->carryN--) {
                put(0xFF, $self->out);
            }
            $self->buffer = ($newBuffer & 0xFF);
        }

        $self->L = ($self->L << 8) & MASK;
        $self->R <<= 8;
    }

    $self->counter++;
}


sub _finish {
    my $self = shift;

    ## 怪しい?
    if ($self->buffer) {
        put($self->buffer, $self->out);
    }

    for (; $self->carryN != 0; $self->carryN--) {
        put(0xff, $self->out);
        if ($self->debug) {
            say "finish: ", bitstr(0xFF);
        }
    }

    for (my $i = 0; $i < 4; $i++) {
        if ($self->debug) {
            say "finish() => L: ", bitstr($self->L);
        }
        put($self->L >> 24, $self->out);
        $self->L = ($self->L << 8) & MASK;
    }
}

sub decode {
    my ($self, $bin) = @_;
    $self->init(\$bin);

    for (my $i = 0; $i < 4; $i++) {
        $self->D = ($self->D << 8) | get($self->out);
        if ($self->debug) {
            say "D: ", bitstr($self->D);
        }
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

    my $r   = floor($self->R / $total);
    my $pos = min( $total - 1, floor($self->D / $r) );

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
        $self->R <<= 8;
        $self->D = ($self->D << 8) | get($self->out);
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
