#!/usr/bin/perl
#
# Compare various cache backends
#
use Cwd qw(realpath);
use Data::Dump qw(dump);
use DBI;
use DBD::mysql;
use File::Basename;
use File::Path;
use Getopt::Long;
use Hash::MoreUtils qw(slice_def);
use Text::Table;
use YAML::Any qw(DumpFile);
use warnings;
use strict;

# Load local version of Cache::Benchmark until we get changes into CPAN
# version
#
my $cwd = dirname( realpath($0) );
unshift( @INC, "$cwd/lib" );
require Cache::Benchmark;

my %cache_generators = cache_generators();

sub usage {
    printf(
        "usage: %s [-I path,...] [-c count] [-s set_frequency] [-d driver_regex] [-x|--complex]\ndrivers: %s\n",
        $0, join( ", ", sort keys(%cache_generators) ) );
    exit;
}

usage() if !@ARGV;
my $drivers_pattern = '.';
my $count           = 10000;
my $set_frequency   = 0.05;
my ( $incs, $complex );
GetOptions(
    'c|count=i'         => \$count,
    's|set_frequency=s' => \$set_frequency,
    'd|drivers=s'       => \$drivers_pattern,
    'x|complex'         => \$complex,
    'I=s'               => \$incs,
);
my $value =
  $complex
  ? { map { ( $_, scalar( $_ x 100 ) ) } qw(a b c d e) }
  : scalar( 'x' x 500 );
my $sets = int( $count * $set_frequency );

unshift( @INC, split( /,/, $incs ) ) if $incs;
require CHI;

print "running $count iterations\n";
print "CHI version $CHI::VERSION\n";

my $data = "$cwd/data";
rmtree($data);
mkpath( $data, 0, 0775 );

my %common_chi_opts = ( on_get_error => 'die', on_set_error => 'die' );

my @drivers = grep { /$drivers_pattern/ } keys(%cache_generators);
my %caches = map { ( $_, $cache_generators{$_}->() ) } @drivers;
print "Drivers: " . join( ", ", @drivers ) . "\n";

my $cb = new Cache::Benchmark();
$cb->init( keys => $sets, access_counter => $count, value => $value );

my $tb = Text::Table->new( 'Cache', 'Gets', 'Sets', 'Get time', 'Set time',
    'Run time' );

my @names = sort keys(%caches);
my %results;
foreach my $name (@names) {
    print "Running $name...\n";
    my $cache = $caches{$name};
    $cb->run($cache);
    my $result    = $cb->get_raw_result;
    my @colvalues = (
        $name,
        $result->{reads},
        $result->{writes},
        sprintf( "%.2fms", $result->{get_time} * 1000 / $result->{reads} ),
        sprintf( "%.2fms", $result->{set_time} * 1000 / $result->{writes} ),
        sprintf( "%.2fs",  $result->{runtime} )
    );
    $tb->add(@colvalues);
    $results{$name} = \@colvalues;
}
print $tb;
DumpFile( 'results.dat', \%results );

sub cache_generators {
    return (
        chi_berkeleydb => sub {
            CHI->new(
                %common_chi_opts,
                driver   => 'BerkeleyDB',
                root_dir => "$data/chi/berkeleydb",
            );
        },
        chi_fastmmap => sub {
            CHI->new(
                %common_chi_opts,
                driver   => 'FastMmap',
                root_dir => "$data/chi/fastmmap",
            );
        },
        chi_file => sub {
            CHI->new(
                %common_chi_opts,
                driver   => 'File',
                root_dir => "$data/chi/file",
                depth    => 2
            );
        },
        chi_memcached_std => sub {
            CHI->new(
                %common_chi_opts,
                driver  => 'Memcached',
                servers => ["localhost:11211"],
            );
        },
        chi_memcached_fast => sub {
            CHI->new(
                %common_chi_opts,
                driver  => 'Memcached::Fast',
                servers => ["localhost:11211"],
            );
        },
        chi_memcached_libmemcached => sub {
            CHI->new(
                %common_chi_opts,
                driver  => 'Memcached::libmemcached',
                servers => ["localhost:11211"],
            );
        },
        chi_memory => sub {
            CHI->new(
                %common_chi_opts,
                driver    => 'Memory',
                datastore => {},
            );
        },
        chi_dbi_mysql => sub {
            my $mysql_dbh =
              DBI->connect( "DBI:mysql:database=chibench;host=localhost",
                "chibench", "chibench" );
            CHI->new(
                %common_chi_opts,
                driver       => 'DBI',
                dbh          => $mysql_dbh,
                create_table => 1,
            );
        },
        chi_dbi_sqlite => sub {
            my $sqlite_dbh =
              DBI->connect( "DBI:SQLite:dbname=$data/sqlite.db",
                "chibench", "chibench" );
            CHI->new(
                %common_chi_opts,
                driver       => 'DBI',
                dbh          => $sqlite_dbh,
                create_table => 1,
            );
        },
        cache_fastmmap => sub {
            require Cache::FastMmap;
            my $fastmmap_file = "$data/fastmmap.fm";
            Cache::FastMmap->new( share_file => $fastmmap_file, );
        },
        cache_memcached_std => sub {
            Cache::Memcached->new( servers => ["localhost:11211"], );
        },
        cache_memcached_fast => sub {
            Cache::Memcached::Fast->new( servers => ["localhost:11211"], );
        },
        cache_memcached => sub {
            Cache::Memcached::libmemcached->new( servers => ["localhost:11211"],
            );
        },
        cache_cache_file => sub {
            require Cache::FileCache;
            Cache::FileCache->new(
                {
                    cache_root  => "$data/cachecache/file",
                    cache_depth => 2,
                }
            );
        },
        cache_cache_memory => sub {
            require Cache::MemoryCache;
            Cache::MemoryCache->new();
        },
    );
}
