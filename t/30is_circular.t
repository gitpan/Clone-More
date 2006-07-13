
use strict;
use warnings;

use Test::More qw( no_plan );
use Clone::More qw( is_circular );

use_ok( 'Clone::More' );

my @c_arr;
my @nc_arr;
my %c_hash;
my %nc_hash;

$c_arr[0] = \@c_arr;
$nc_arr[0] = 1;
$c_hash{'a'} = \%c_hash;
$nc_hash{'a'} = 1;

ok( is_circular( \@c_arr ) );
ok( is_circular( \%c_hash ) );
ok( ! is_circular( \@nc_arr ) );
ok( ! is_circular( \%nc_hash ) );

my $hash_ca = {
	'a' => [
		[
			[
				[
					{
						'b' => [
							[
								\@c_arr
							]
						]
					}
				]
			]
		]
	]
};
ok( is_circular( $hash_ca ) );

my $hash_ch = {
	'a' => [
		[
			[
				[
					{
						'b' => [
							[
								\%c_hash
							]
						]
					}
				]
			]
		]
	]
};
ok( is_circular( $hash_ch ) );

my $hash_nh = {
	'a' => [
		[
			[
				[
					{
						'b' => [
							[
								\%nc_hash
							]
						]
					}
				]
			]
		]
	]
};
ok( ! is_circular( $hash_nh ) );
