package CHI::t::Driver::Subcache;
use strict;
use warnings;
use CHI::Test;
use base qw(CHI::t::Driver);

my ( $cache, $subcache, $key, $value, $key2, $value2 );

sub set_standard_keys_and_values {
    my ($self) = @_;

    my ( $keys, $values ) = $self->SUPER::set_standard_keys_and_values();

    # keys for file driver have max length of 255 or so
    # but on windows xp, the full pathname is limited to 255 chars as well
    $keys->{'large'} = scalar( 'ab' x ( $^O eq 'MSWin32' ? 64 : 120 ) );

    return ( $keys, $values );
}

sub test_set_and_remove : Tests(80) {
    my ($self) = @_;
    ( $key, $value, $key2, $value2 ) = $self->kvpair(2);

    $cache    = $self->{cache};
    $subcache = $cache->subcaches->[0];

    my $test_remove_method = sub {
        my ( $desc, $remove_code ) = @_;
        $desc = "testing $desc";

        confirm_caches_empty("$desc: before set");
        $cache->set( $key,  $value );
        $cache->set( $key2, $value2 );
        confirm_caches_populated("$desc: after set");
        $remove_code->();

        confirm_caches_empty("$desc: before set_multi");
        $cache->set_multi( { $key => $value, $key2 => $value2 } );
        confirm_caches_populated("$desc: after set_multi");
        $remove_code->();

        confirm_caches_empty("$desc: before return");
    };
    $test_remove_method->(
        'remove', sub { $cache->remove($key); $cache->remove($key2) }
    );
    $test_remove_method->(
        'expire', sub { $cache->expire($key); $cache->expire($key2) }
    );
    $test_remove_method->(
        'expire_if',
        sub {
            $cache->expire_if( $key,  sub { 1 } );
            $cache->expire_if( $key2, sub { 1 } );
        }
    );
    $test_remove_method->( 'clear', sub { $cache->clear() } );
}

sub confirm_caches_empty {
    my ($desc) = @_;
    ok( !defined( $cache->get($key) ),
        "primary cache is not populated with '$key' - $desc" );
    ok( !defined( $subcache->get($key) ),
        "subcache is not populated with '$key' - $desc" );
    ok( !defined( $cache->get($key2) ),
        "primary cache is not populated #2 with '$key2' - $desc" );
    ok( !defined( $subcache->get($key2) ),
        "subcache is not populated #2 with '$key2' - $desc" );
}

sub confirm_caches_populated {
    my ($desc) = @_;
    is( $cache->get($key), $value,
        "primary cache is populated with '$key' - $desc" );
    is( $subcache->get($key), $value,
        "subcache is populated with '$key' - $desc" );
    is( $cache->get($key2), $value2,
        "primary cache is populated with '$key2' - $desc" );
    is( $subcache->get($key2), $value2,
        "subcache is populated with '$key2' - $desc" );
}

1;
