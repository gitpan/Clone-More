
use Test::More qw( no_plan );

use Data::Dumper;
use Clone::More qw( clone );
use_ok( 'Clone::More' );

my $structures = [
	1,
	'1',
	1.0,
	'1.0',
	[ qw( one ) ],
	[ qw( one two three four five ) ],
	{ 'key' => 'value' },
	{ 'key' => { 'key' => 'value' } },

	# More complex
	[
		{
			'key' => {
				'arr' => [ qw( some thing here ) ],
				'AoH' => [ { 'a' => { 'b' => { 'c' => { 'd' => 'e' } } } } ],
			}
		},
		[
			[
				'key' => {
					'arr' => [ qw( some thing here ) ],
					'AoH' => [ { 'a' => { 'b' => { 'c' => { 'd' => 'e' } } } } ],
				}
			],
		],
	],
];

for ( @$structures ) {
	ok( $_, 'Some structure was gathered' );
	is_deeply( $_, clone( $_ ), join( ' ', 'A', ref( $_ ), qw( structure was cloned appropriately ) ) );
}
