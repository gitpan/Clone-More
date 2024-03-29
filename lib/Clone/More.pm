# Working version
# $Revision: 1.6 $ $Date: 2006/07/14 18:36:38 $
package Clone::More;

use strict;

use Exporter;
use XSLoader;

our @ISA             = qw( Exporter );
our @EXPORT          = qw( );
our @EXPORT_OK       = qw( clone circular is_circular );
our $VERSION         = '0.90.2';

# Configuration variables
our $BREAK_REFS      = 0;
our $IGNORE_CIRCULAR = 0;
our $CIRCULAR_ACTION = 0;
our $ALLOW_HOOKS     = 1;

XSLoader::load( 'Clone::More', $VERSION );

sub clone {

	# No real need for this, more of an easy way for people
	# to take a gander into the Perl implementation to see
	# what/where/when/why and how the XS is being called
	warn "Use of depth is deprecated in clone() at: " . 
		join( ' ', caller() ) . "\n" unless( @_ == 1 );
	return cloneXS( $_[0] );
}

sub is_circular {
	return circularXS( @_ );
}

sub circular {
	return is_circular( @_ );
}

1;
__END__

=head1 NAME

Clone::More - Natively copying Perl data structures

=head1 SYNOPSIS

	use Clone::More qw( clone );

	my $structure = [
		{ 'key' => 'value' }
	];

	for my $set ( @$structure ) {
		my $clone = clone( $set );
		
		for ( keys %$clone ) {
			print "Everything matches" if ( exists( $set->{$_} ) && $set->{$_} eq $clone->{$_} );
		}
	}


=head1 DESCRIPTION

This is intended to act as a utility in order to natively clone data structures via a simple Perl
interface.  Will ensure that all references will be separated from the parent data strure, yet kept
relative to the new structure (if need be).

Please take a look at the WARNINGS, GOTCHAS and FUTURE DEVELOPMENT sections, as resources to see
if this module is fully capable of doing everything that you want it to do (and it will do most
everything).

=head2 HISTORY

C<Clone::More> originally began as a patch for the C<Clone> module.  It was found, with a group
I was working with at the time, that there was a pretty noticiable memory leak in the module
while cloning massively complex Perl data structures.  In an attempt to find the source of the leak
and subit the path to the L<Clone> author, Ray Finch, it took a complete overhaul in order for me
to stop the leak.  Since then, I have been working with Ray Finch to see what we can work out in
getting C<Clone> up to date with the patches I have applied.  Unfortunately, we have fallen out
of contact and arrose the counterpart to this module, L<Clone::Fast>.  From there, I added more
programatic functionality, deviating from the simplicity of L<Clone::Fast> and L<Clone> alike.
Thus, C<Clone::More> was born!

=head2 EXPORT

=head3 clone

Clone is the primary function from within the provided module.  By passing a scalar reference to this
routine, you will expect to get a returned scalar reference that will no longer have any reference to
the originating reference.  However, references deeper into the structure will still uphold the references
within the structure.

Example being:

	use Clone::More qw( clone );

	my $foo = { 'a' => 'b' };
	my $bar = { 'a' => $foo, 'b' => $foo };

	my $baz = clone( $bar );

	print "\$foo and \$bar are different references\n" if ( $foo ne $bar );
	print "\$foo->{'a'} and \$bar->{'a'} are different references\n" if ( $foo->{'a'} ne $bar->{'a'} );
	print "\$foo->{'a'} and \$foo->{'b'} are the same, however\n" if ( $foo->{'a'} eq $bar->{'b'} );

This makes sense, although this can be modified as well.  By using the internal variable, BREAK_REFS, you
are also allowed to break internal references (may break up circular references, although won't fix
the circular reference in the originating reference).

=head3 circular

Given a single data structure, will return a boolean value indicating wether or not there is a circular
reference embedded within the structure.

	use Clone::More qw( circular );

	my @a;
	$a[0] = \@a;

	my @b;
	$b[0] = { 'key' => 'value' };

	# Will print '@a has a circular reference'
	print ( ( circular( \@a ) ) ? "\@a has a circular reference\n" : "\@a has NO circular reference\n" );

	# Will print '@b has NO circular reference'
	print ( ( circular( \@b ) ) ? "\@b has a circular reference\n" : "\@b has NO circular reference\n" )


NOTE (Same will apply for C<is_circular>): Circular references are a little tricky.  C<Clone::More>, currently,
has an embedded ability to find some in most cases.  However, there still remains the fact that it is quite
tricky to seperate a circular reference from a normal reference set.  Therefore, the difference between:

	my $circular = [ qw( one two ) ];
	$circular->[2] = \$r;
	$circular->[3] = \$r;
	$circular->[4] = \$r;

and:

	my $not_circ = [ qw( one two ) ];
	my $wth_circ = [ qw( one two ) ];
	$r->[2] = \$wth_circ;
	$r->[3] = \$wth_circ;
	$r->[4] = \$wth_circ;

Are very subtile, yet very profound.  One will cause a very fast circular memory leak, due to the circular
reference, while the other will not; being there is no circular reference.  Therefore, the reliability of
these tests may still leave something yet to be desired.  I will continue development on these exported
functions until I am more confident about their behavior.

=head3 is_circular

Is an alias for C<Clone::More::circular>.  Makes for more aesthetically pleasing programming.  More 'self
documenting' then C<Clone::More::circular>.

Therefore:

	use Clone::More qw( circular is_circular );

	my @a;
	$a[0] = \@a;

	my @b;
	$b[0] = { 'key' => 'value' };

	print "1" if ( circular( \@a ) == is_circular( \@a ) );
	print "1" if ( circular( \@b ) == is_circular( \@b ) );
	print "0" if ( circular( \@a ) == is_circular( \@b ) );
	print "\n";
	
	# You will see the following printed to STDOUT:
	# '110'

=head1 PROGRAMATIC HOOKS

Much like the Perl Storable module (available in all current Perl distributions), C<Clone::More> allows for
hooks that will be accessed when cloning any object that has a hook defined.  This can be very handy where
Inside Out objects would not normally be cloned.  WHHAAATT????  What I mean is, only the reference of an
object will be cloned, not the internal stash of the object.  Therefore, accessors that are defined within
an inside out object will not be cloned.  There is no real safe way to do this, with the exception of cloning
the entire class stash, breaking more things than it will fix.  Again, the reference of the object will be
fully cloned, and the object it's self will be a new reference, although it will be an empty object.  Subsiquently,
such as most inside out objects, the blessed reference is of a scalar type; an integer indicating the object id.
When cloning this, you would end up with two objects of the same type with the same object id.  The hooks
have been added in an attempt to prevent this from happening.

=head2 CLONEMORE_clone

Again, much like L<Storable> (though a little better, I hope), the function will be called *AFTER* the clone
operation has completed on the object being cloned.  The routine will have two scalar references passed
via the stack, representing both the cloned object as well as the source of the clone.  This *should* allow
for the programatic manipulation of the object before it gets returned to the caller, or placed into the
refering structure.

As an example, I will use the following object to define a 'hooked' object:

	package Hookable;

	use strict;
	use warnings;

	use Clone::More qw( clone );
	
	sub new { bless {}, shift }

	sub CLONEMORE_clone {

		# Where clone is the cloned object from the source, where source
		# was the originating reference
		my ( $clone, $source ) = @_;

		# I am going to pretend the source has a list of defined methods,
		# of which I want to clone and transfer to the clone; outside
		# of the blessed hash-refrence that is the source of the object
		$clone->$_( clone( $source->$_() ) ) for ( qw( get_method_1 get_method_2 get_method_3 ) );

		# At this point, the cloned object will also have a set of cloned
		# fields from the source.  If, by chance, any of the values of the
		# defined attribtes are other 'Hookable' objects, the same routine
		# will be called on that object as well.
		
		# The API requires me to return the new $clone, this will be returned to
		# the caller
		return $clone;
	}

Using the package from above, I will now use an example of a script where I will demonstrate how
the whole thing comes together:

	#!/usr/bin/perl -w
	
	use strict;

	use Clone::More qw( clone );

	my $hookable  = Hookable->new();
	$hookable->{'hash_stuff'} = 'some value';
	
	my $structure = {
		'hookable' => $hookable,
		'new'      => Hookable->new(),
		'deeply'   => {
			'hookable' => $hookable,
			'new'      => Hookable->new();
		},
	};

	my $cloned = clone( $sturcture );

This script will demonstrate a number of things.  1.) C<Clone::More::clone> will, automagically call the hook
on all instances of the Hookable.  Though the hash_stuff key will automatically be cloned before the hook is ever
called.  Subsiquently, the hashes in both values of hookable in the hash will be references of one another, though
not references to the originating object.  The Hookable->new() object, on the other hand, will not be referenced
to anything of the similar like.

As a secondary note, it was originally thought to allow for hooks to show up before and after the cloning of the
object.  Though, that would allow for the full change of the cloning type; this would be very bad.  Also, given
that it is somewhat reasonable to believe hooks will only be used with inside out objects, we can also assume the
cloning of a simple referent will be so lightweight that there will still be the benifit of having clone hook into
the object.  If anyone has beef with this paradigm, let me know and I'll change it.

=head1 CONFIGURATION VARIABLES 

=over

=item $Clone::More::ALLOW_HOOKS

The C<ALLOW_HOOKS> variable will allow for the toggling behavior, telling C<Clone::More> to check for
hooks when cloning objects.  (See C<PRGRAMATIC HOOKS> for more details).  The varialble will default
to 'on', where C<Clone::More> will always check each object for hooks defined within the object.

	use Clone::More qw( clone );
	
	$Clone::More::ALLOW_HOOKS = 1; # No need, this is default

	my $object = HasHooks->new();

	package HasHooks;

	use strict;
	use warnings;

	sub new { bless {}, shift }

	sub CLONEMORE_clone {
		my ( $clone, $source ) = @_;

		# Re-assigning the reference will now return the reference from the
		# C<Clone::More::clone> when cloning a HasHooks object, rather than
		# a cloned reference to the object.
		$clone = { 'object' => $clone };
		return $clone;
	}

=item $Clone::More::BREAK_REFS

	use Clone::More qw( clone );
	$Clone::More::BREAK_REFS = 1;

	my $foo = { 'a' => 'b' };
	my $bar = { 'a' => $foo, 'b' => $foo };

	my $baz = clone( $bar );

	print "\$foo and \$bar are different references\n" if ( $foo ne $bar );
	print "\$foo->{'a'} and \$bar->{'a'} are different references\n" if ( $foo->{'a'} ne $bar->{'a'} );
	print "\$foo->{'a'} and \$foo->{'b'} are no longer the same\n" if ( $foo->{'a'} ne $bar->{'b'} );

You will see that by adding the BREAK_REFS flag, you will change the overall behavior of the routine.
The BREAK_REFS flag must, simply, have truthfullness (as far as Perl is concerned) in order to be 'on'.

Whereas:

	$Clone::More::BREAK_REFS = 1;

	# Will do the same thing as:
	
	$Clone::More::BREAK_REFS = 'yes';

	# Will do the same thing as:
	
	$Clone::More::BREAK_REFS = ( 2 != 1 );

Albeit handy, this feature may also slow down the module by some degree.  Therefore, there is some flexibility
into whether or not you need to use this, and the functionality can be compiled out of the object; speeding up
the cloning ability.  Therefore, Re-compiling the mdule without MINDFUL_REFS will increase the speed of the
module by a degree of 3x!  If you KNOW you will never use the $Clone::More::BREAK_REFS and are confident
with manually installing Perl modules from source, it is recommended you do so.  There are comments in the XS source
that will detail how to do this.

This configuration only applies to the C<Clone::More::clone> routine.

=item $Clone::More::IGNORE_CIRCULAR

This configuration flag will tell Clone to ignore all circular reference checks.  Unless you are completely
confident the structures that are being cloned WILL NEVER contain a circular reference, it is not fully
recommended to use this configuration variable.

By default, this variable is turned 'off'.  To toggle, the variable must simply evaulate to true in Perl.

Whereas:

	$Clone::More::IGNORE_CIRCULAR = 1;

	# Will do the same thing as:
	
	$Clone::More::IGNORE_CIRCULAR = 'yes';

	# Will do the same thing as:
	
	$Clone::More::IGNORE_CIRCULAR = ( 2 != 1 );

This configuration only applies to the C<Clone::More::clone> routine.

=item $Clone::More::CIRCULAR_ACTION

This configuration is mutually exclucive of the $Clone::More::IGNORE_CIRCULAR.  More specifically,
the variable will only be validiated when $Clone::More::IGNORE_CIRCULAR is turned 'off' (by default).

This configuration is currently a bit-mask operator, telling C<Clone::More::clone> what to do when
it comes across a circular reference.  By default, the zero bit is assigned to the configuration,
telling C<Clone::More::clone> to create a new circular reference within the new structure (no longer
referencing the source of the clone).

It should be noted that the current version of C<Clone::More> will use the bit-mask as a literal integer,
though wanted to incept the idea of having a bit-mask here to allow for future development.  The useage
of bit-wise OR ('|') will do nothing but warn and default to the zero-bit.

Operations include:

=over

=item 0b000 - Zero bit (default)

As described earlier, will simply create a new circular reference within the new structure, no
longer referencing the source of the clone.

	my @b;
	$b[0] = \@b; # This is circular

	use Clone;
	$Clone::More::CIRCULAR_ACTION = 0b000; # 0 will work here too

	my $a = clone( $b );

	# Now $a is also a circular reference with no reference to $b - you just
	# doubled your memory leak ;)

=item 0b001 - One bit

Will keep the circular reference, although keeping the reference from the source structure.  In other
words, will not clone the circular reference but will still contain a structure therein.

	my @b;
	$b[0] = \@b; # This is circular

	use Clone;
	$Clone::More::CIRCULAR_ACTION = 0b001; # 1 will work here too

	my $a = clone( $b );

	# Now $a is a new reference, with a pointer to $b[0] in $a[0].
	# Although not 'cloned', you didn't double your memory leak either!

=item 0b0010 - Two bit

Will simply return an undef as the value for the ciruclar reference.

	my @b;
	$b[0] = \@b; # This is circular

	use Clone;
	$Clone::More::CIRCULAR_ACTION = 0b010; # 2 will work here too

	my $a = clone( $b );

	# $a is now undef

=item 0b100 - Four bit

Will simply warn there is a circular reference and default back to the zero bit.

=item All others

Will warn of the invalid usage of the configuration variable and default to the zero bit.

=back

=back

=head1 EXAMPLES

=over

=item Using Clone::More::clone

C<Clone::More::clone> is an exported routine.  You can either use it as such, or simply call it
directly on the package.

Example w/ export:

	use Clone::More qw( clone );

	my $source = { 'a' => 'b' };
	my $clone  = clone( $source );

Example w/o export

	use Clone::More;

	my $source = { 'a' => 'b' };
	my $clone  = Clone::More::clone( $source );

=item Using Clone::More::(is_)?circular

The C<Clone::More::(is_)?circular> routines will allow you to test whether or not a structure
contains a ciruclar reference or not.

=back

=head1 GOTCHAS/WARNINGS

=over

=item bless()'ed references (Perl objects)

This module works great for blessed references, how ever the paradigm changes when trying to clone
inside out objects (or Conway's 'flywaight' style of object creation).  Clone does not, nor will not,
clone the stash of an object's class; this would break more than anything.  Given this, HOOKS have
been provided in order to programatically handle wierd stuff like this.  I am hoping applications,
developers and all of the like whom are using inside out objects will know what the heck it is I'm
talking about here.  There is a lot more information about this in the PROGRAMATIC HOOKS section.

=back

=over

=item ithreads

I really have no idea how this will work in a treadded environment.  It should be OK, but there is no
development that has taken this into account.

=back

=over

=item Hooks and circular evaluations

Both Clone hooks and deep circular evaluations are pretty new, and may have some problems within them.
Please, if you find anything you don't expect; feel free to bug it and I will try to patch it up
ASAP.

=back

=head1 OPTIMIZATION HACKS

I have, and will contiue to, wrap all the new features into easily optimized C<#ifdef> conditions.  Where
each new feature will have it's own definition, where commenting out of the definition will allow for much
less processing.  Using this is the pure basis of L<Clone> (more details within the L<Clone> docs), whereas
all of the new functionality found in C<Clone::More> is optimized out for a much faster L<Clone>.

I'm not going to explain much more, though if you are relitively tuned up in your C, you can take a gander
at the XS implementation and play around with it if you'd like!

=head1 SEE ALSO

=over

=item L<Storable>

This will, essentially, do the exact same thing as what this module does.  The difference being that Storable will
freeze the chunk of memory you are trying to clone, and thaw that binary chunk to another piece of memory.  This works
well, yet is very slow.  Subsiquently, Storable, as of Perl 5.8, is CORE; and may be more trusted than this :)

=item L<Clone>

The 'basis' of C<Clone::More>, where L<Clone> is simply a very optimized version of C<Clone::More>.  Where hooks, some
exported routines and advanced functionality have been removed.

=back

=head1 AUTHOR

Trevor Hall, E<lt>wazzuteke@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Trevor Hall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
