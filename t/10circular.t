
use strict;
use warnings;

use Test::More qw( no_plan );
use Clone::More;

use_ok( 'Clone::More' );

my $hash   = {};
my $array  = [];
my $object = Foo->new();

$hash->{'a'}   = $hash;
$array->[0]    = $array;
$object->{'a'} = $object;


# 	// Currently supported options.
# 	// 0b000  ( 0 ) => Will continue the circular reference (default)
# 	// 0b001  ( 1 ) => Will return an incremented version of the source
# 	// 0b010  ( 2 ) => Will undef the value
# 	// 0b100  ( 4 ) => Will warn about the circular reference, acting as 0b000
$Clone::More::CIRCULAR_ACTION = 0;

my $test = Clone::More::clone( $hash );
ok( $test ne $hash );
ok( test_dumper( $test, $hash ) );
ok( $test eq $test->{'a'} );

$test = Clone::More::clone( $array );
ok( $test ne $array );
ok( test_dumper( $test, $array ) );
ok( $test->[0] ne $array->[0] );
ok( $test->[0] eq $test );

$test = Clone::More::clone( $object );
ok( $test ne $object );
ok( ref( $test ) eq ref( $object ) );
ok( test_dumper( $test, $object ) );
ok( $test->{'a'} eq $test );

$Clone::More::CIRCULAR_ACTION = 1;
ok( $Clone::More::CIRCULAR_ACTION == 1 );

$test = Clone::More::clone( $hash );
ok( $test ne $hash );
ok( $test->{'a'} ne $test );
ok( $test->{'a'} eq $hash );
ok( $test->{'a'} eq $hash->{'a'} );
ok( ! test_dumper( $test, $hash ) );
is_deeply( $test, $hash );

$test = Clone::More::clone( $array );
ok( $test ne $array );
ok( $test->[0] ne $test );
ok( $test->[0] eq $array && $test->[0] eq $array->[0] );
ok( ! test_dumper( $test, $array ) );
is_deeply( $test, $array );

$test = Clone::More::clone( $object );
ok( $test ne $object );
ok( $test->{'a'} ne $test && $test->{'a'} eq $object );
ok( ! test_dumper( $test, $object ) );
is_deeply( $test, $object );

$Clone::More::CIRCULAR_ACTION = 2;
ok( $Clone::More::CIRCULAR_ACTION == 2 );

$test = Clone::More::clone( $hash );
ok( $test ne $hash );
ok( $test->{'a'} ne $test );
ok( ref( $test->{'a'} ) eq 'SCALAR' );
ok( ! test_dumper( $test, $hash ) );

$test = Clone::More::clone( $array );
ok( $test ne $array );
ok( $test->[0] ne $test );
ok( ref( $test->[0] ) eq 'SCALAR' );
ok( ! test_dumper( $test, $array ) );

open STDERR, ">$0.tmp" or ok( 0, "$!" );
$Clone::More::CIRCULAR_ACTION = 4;
ok( $Clone::More::CIRCULAR_ACTION == 4 );

$test = Clone::More::clone( $hash );
ok( $test ne $hash );
ok( test_dumper( $test, $hash ) );
ok( $test eq $test->{'a'} );

$test = Clone::More::clone( $array );
ok( $test ne $array );
ok( test_dumper( $test, $array ) );
ok( $test->[0] ne $array->[0] );
ok( $test->[0] eq $test );

$test = Clone::More::clone( $object );
ok( $test ne $object );
ok( ref( $test ) eq ref( $object ) );
ok( test_dumper( $test, $object ) );
ok( $test->{'a'} eq $test );

close STDERR;

open my $output, "$0.tmp" or ok( 0, "$!" );
my @lines = <$output>;
close $output;
ok( scalar( @lines ) == 3 );
ok( $_ =~ /Warning/i ) or diag( $_ ) for ( @lines );
ok( unlink( "$0.tmp" ) );

sub test_dumper {
	my ( $a, $b ) = @_;

	eval( "use Data::Dumper;" );
	return 1 if ( $@ );

	return ( Dumper( $a ) eq Dumper( $b ) );
}

package Foo;

sub new { return bless {}, shift; }
