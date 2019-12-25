package Bencher::Scenario::SortingByKey;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

our $scenario = {
    summary => 'Benchmark various techniques to sort array by some computed key',
    participants => [

        {
            name => 'uncached',
            description => <<'_',

This technique does not cache the sort key and computes it everytime they are
compared. This performance of this technique depends on how expensive the
computation of key is. (In this benchmark, the computation is very cheap.)

In Perl code:

    @sorted = sort { GEN_KEY($a) cmp GEN_KEY($b) } @array;

_
            code_template => 'state $array=<array>; sort { -$a <=> -$b } @$array', result_is_list=>1,
        },

        {
            name => 'ST',
            description => <<'_',

Schwartzian transform (also known as map/sort/map technique) caches the sort key
in an arrayref. It works by constructing, for each array element, a container
record (most often anonymous arrayref) containing the original element and the
key to be sorted. Later after the sort, it discards the anonymous arrayrefs. The
arrayref construction is a significant part of the total cost, especially for
larger arrays.

In Perl code:

    @sorted = map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [$_, GEN_KEY($_)] } @array;

_
            code_template => 'state $array=<array>; map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [$_, -$_] } @$array', result_is_list=>1,
        },

        {
            name => 'GRT',
            description => <<'_',

Guttman-Rosler transform, another map/sort/map technique, is similar to ST. The
difference is, the computed key is transformed into a fixed-length string that
can be compared lexicographically (thus eliminating the need for the Perl custom
sort block). The original element is also transformed as a string and
concatenated into the string. Thus, GRT avoids the construction of the anonymous
arrayrefs. As a downside, the construction of the key string can be tricky.

In Perl code (assuming the compute key is transformed into a fixed 4-byte
string:

    @sorted = map { substr($_, 4) } sort map { pack("NN", -$_, $_) } @array;

_
            code_template => 'state $array=<array>; map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [$_, -$_] } @$array',
            result_is_list=>1,
        },

        {
            name => '2array',
            description => <<'_',

This technique caches the compute key in a single array. It also constructs an
array of indexes, sorts the array according to the array keys, then constructs
the final sorted array using the sorted indexes.

Compared to GRT, it constructs far fewer anonymous arrayrefs. But it still
requires Perl custom sort block.

In Perl code:

    @indexes = 0 .. $#array;
    @keys    = map { GEN_KEY($_) } @array;
    @sorted  = map { $array[$_] } sort { $keys[$a] <=> $keys[$b] } @indexes;

_
            code_template => 'state $array=<array>; my @keys = map { -$_ } @$array; my @indexes = 0..$#{$array}; map { $array->[$_] } sort { $keys[$a] <=> $keys[$b] } @indexes',
            result_is_list=>1,
        },

        {
            name => 'Sort::Key::nkeysort',
            module => 'Sort::Key',
            function => 'nkeysort',
            description => <<'_',

This module also caches the compute keys. It's faster because it's implemented
in XS.

_
            code_template => 'state $array=<array>; Sort::Key::nkeysort(sub { -$_ }, @$array)',
            result_is_list => 1,
        },


    ],
    datasets => [
        {name=>'10'   , args=>{array=>[map {int(   10*rand)} 1..10   ]}},
        {name=>'100'  , args=>{array=>[map {int(  100*rand)} 1..100  ]}},
        {name=>'1000' , args=>{array=>[map {int( 1000*rand)} 1..1000 ]}},
        {name=>'10000', args=>{array=>[map {int(10000*rand)} 1..10000]}},
    ],
};

1;
# ABSTRACT:

=head1 prepend:SEE ALSO

L<Sort::Maker> describes the various sort techniques (ST, GRT)

L<Sort::Key>
