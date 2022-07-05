package CPT::Parameter;
use Moose::Role;
use strict;
use warnings;
use autodie;
use Carp;

#requires 'galaxy_command';
requires 'galaxy_input';
requires 'galaxy_output';
requires 'validate_individual';
requires 'getopt_format';

# Long name for this parameter (mandatory)
has 'name' => ( is => 'rw', isa => 'Str' );

# Short name for this paramter (optional)
has 'short'       => ( is => 'rw', isa => 'Str' );
has 'multiple'    => ( is => 'rw', isa => 'Bool' );
has 'description' => ( is => 'rw', isa => 'Str' );

# Attr
# Default supplied parameters
has 'default'  => ( is => 'rw', isa => 'Any' );
# User supplied values
has 'value'    => ( is => 'rw', isa => 'Any' );
has 'required' => ( is => 'rw', isa => 'Bool' );
has 'hidden'   => ( is => 'rw', isa => 'Bool' );

# Set of error messages to be returned
has 'errors'   => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

# Unimplemented
# Are there any implications of setting this
has 'implies' => ( is => 'rw', isa => 'ArrayRef' );

# Internal
has '_index' => ( is => 'rw', isa => 'Int', default => 0 );

# Galaxy Specific
has '_galaxy_specific' => (is => 'rw', isa => 'Bool', default => 0);
# implies option is somehow intertwined with whether or not this is being produced for use in galaxy.
has '_show_in_galaxy' => (is => 'rw', isa => 'Bool', default => 1);
# This is a custom override. If the object is hidden by default, it will causae it to be shown. If the object is visible by default, it can cause it to be hidden.



sub galaxy_command {
	my ($self) = @_;
	my $value = $self->get_galaxy_command_identifier();

	# If it's hidden, specific to galaxy, and hidden from galaxy users,
	# then it is safe to assume we've specified a SANE default.
	if($self->hidden() && $self->_galaxy_specific()){
		$value = $self->default();
	}
	my $string;
	
	# If it's a repeat, we handle that
	$string .= $self->handle_possible_galaxy_command_repeat_start();
	# If it's required we set it to a value IF we have one. Otherwise value
	# will be the galaxy_identifier.
	if($self->required()){
		$string .= sprintf( '--%s "${%s}"' . "\n",
			$self->get_galaxy_cli_identifier(), $value
		);
	}else{
		# If
		# This code is only relevant if we're multiple, otherwise the loop will
		# not pass here
		if ( !$self->multiple() ){
			$string .= sprintf('#if $%s and $%s is not "None":' . "\n",
				$self->get_galaxy_cli_identifier(),
				$self->get_galaxy_cli_identifier()
			);
		}
		# Flag
		$string .= sprintf( '--%s "${%s}"'."\n",
			$self->get_galaxy_cli_identifier(),
			$value
		);
		# End
		if ( !$self->multiple() ){
			$string .= "#end if\n";
		}
	}
	$string .= $self->handle_possible_galaxy_command_repeat_end();
	return $string;
}



sub getOptionsArray {
	my ($self) = @_;
	my @getoptions;
	push( @getoptions, $self->getopt_identifier() );

    my $mod_desc = $self->description();
    if(defined $self->default()){
		if(ref $self->default() eq 'ARRAY'){
			$mod_desc .= sprintf(" (Default: %s)", join(",",@{$self->default()}));
		}else{
			$mod_desc .= sprintf(" (Default: %s)", $self->default());
		}
    }
	if(substr(blessed($self),0,22) eq 'CPT::Parameter::Option'){
			my %kv = %{$self->options()};
			my @k = keys(%kv);
	$mod_desc .= sprintf(" (Options: %s)", 
				join(
					", ", 
					map { $kv{$_} . " [$_]" } @k
				)
			);
	}else{
	}

	push( @getoptions, $mod_desc );

    # Values to copy over: required, hidden, default, values
	my %attr = ();
	if ( $self->required() ) {
		$attr{required} = $self->required();
	}
	if ( $self->hidden() ) {
		$attr{hidden} = $self->hidden();
	}
	if ( $self->default() ) {
		$attr{default} = $self->default();
	}
	push( @getoptions, \%attr );
	return \@getoptions;
}


sub getopt_identifier {
	my ($self) = @_;
	if ( defined( $self->short() ) && length($self->short()) > 0 ) {
		return sprintf( "%s|%s%s%s", $self->name(), $self->short(), $self->getopt_format(), ( $self->multiple() ? '@' : '' ), );
	}
	else {
		return sprintf( "%s%s%s", $self->name(), $self->getopt_format(), ( $self->multiple() ? '@' : '' ), )

	}
}


sub get_galaxy_command_identifier {
	my ($self) = @_;
	if($self->multiple()){
		return sprintf('%s.%s', $self->get_repeat_idx_name(), $self->get_galaxy_cli_identifier());
	}else{
		return $self->get_galaxy_cli_identifier();
	}
}


sub get_galaxy_cli_identifier {
	my ($self) = @_;
	return $self->name();
}


sub is_optional {
	my ($self) = @_;
	# Want coerced to int.
	#return !$self->required();
	if($self->required()){
		return 0;
	}else{
		return 1;
	}
}


sub is_optional_galaxy {
	my ($self) = @_;
	return $self->is_optional() ? "True" : "False";
}


sub update_index {
	my ($self) = @_;
	if($self->multiple()){
		my $size = scalar( @{ $self->value() } );
		# E.g:
		# [1,2,3] , size = 3
		# index = 3
		# size = 3-1 = 2
		# index -> 0
		if ( $self->_index() ge $size - 1 ) {
			$self->_index(0);
		}
		else {
			$self->_index( $self->_index() + 1 );
		}
	}
}


sub reset_index {
	my ($self) = @_;
	$self->_index(0);
}


sub get_value {
	my ($self) = @_;
	if ( defined $self->value() ) {
		if ( $self->multiple ) {
			my @data = @{ $self->value() };
			return $data[ $self->_index() ];
		}
		else {
			return $self->value();
		}
	}else{
		return;
	}
}


sub get_default {
	my ($self) = @_;
	if ( defined $self->default() ) {
		if ( $self->multiple ) {
			my @data = @{ $self->default() };
			return $data[ $self->_index() ];
		}
		else {
			return $self->default();
		}
	}else{
		return;
	}
}



sub validate {
	my ($self) = @_;
	if ( $self->multiple() ) {
		my $errors = 0;
		if( ref($self->value()) ne 'ARRAY' ){
			carp "Author specified a non-array default value for " . $self->name() . ", which allows multiple values. Script author should modify the default value to be an ArrayRef.";
		}
		for my $val ( @{ $self->value() } ) {
			if($self->validate_individual($val) == 0){
				$errors++;
			}
		}
		# Must cast to number otherwise it returns "" which is bad since I use
		# 1/0 as T/F (true = good, false = bad)
		return 0+($errors == 0);
	}
	else {
		return 0+$self->validate_individual($self->value());
	}
}


sub get_repeat_idx_name {
	my ($self) = @_;
	return 'item';
}


sub get_repeat_name {
	my ($self) = @_;
	if($self->multiple()){
		return sprintf('repeat_%s', $self->get_galaxy_cli_identifier());
	}else{
		confess "Tried to get repeat name for non-multiple item";
	}
}


sub handle_possible_galaxy_input_repeat_start {
	my ($self, $xml_writer ) = @_;
	if ( $self->multiple() ) {
		my $title = $self->get_galaxy_cli_identifier();
		$title =~ s/_/ /g;
		# Convert To Title Case  (http://www.davekb.com/browse_programming_tips:perl_title_case:txt)
		$title =~ s/(\w+)/\u\L$1/g;
		$xml_writer->startTag(
			'repeat',
			'name'  => $self->get_repeat_name(),
			'title' => $title,
		);
	}
}


sub handle_possible_galaxy_input_repeat_end {
	my ($self, $xml_writer ) = @_;
	if ( $self->multiple() ) {
		$xml_writer->endTag('repeat');
	}
}



sub handle_possible_galaxy_command_repeat_start {
	my ( $self ) = @_;
	if($self->multiple()){
		return sprintf("#for \$%s in \$%s:\n",
			$self->get_repeat_idx_name(),
			$self->get_repeat_name()
		);
	}else{
		return '';
	}
}


sub handle_possible_galaxy_command_repeat_end {
	my ( $self ) = @_;
	if($self->multiple()){
		return "#end for\n";
	}else{
		return '';
	}
}

sub get_default_input_parameters {
	my ( $self, $type ) = @_;
	my %params = (
		name     => $self->get_galaxy_cli_identifier(),
		optional => $self->is_optional_galaxy(),
		label    => $self->get_galaxy_cli_identifier(),
		help     => $self->description(),
		type     => $type,
	);

	# Multiple values would return ARRAY(0xAAAAAAA) locations, so we have to
	# handle those semi-intelligently until galaxy can handle default values
	# for repeats
	if($self->multiple() && defined $self->default()){
		if(ref($self->default()) ne 'ARRAY'){
			carp "Author specified a non-array default value for " . $self->name() . ", which allows multiple values. Script author should modify the default value to be an ArrayRef.";
		}
		$params{value} = ${$self->default}[0];
	}elsif(!$self->multiple() && defined $self->default()){
		$params{value} = $self->default();
	}

	return %params;
}

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Parameter

=head1 VERSION

version 1.99.4

=head2 galaxy_command

	$file_param->galaxy_command(); # where $file_param is a CPT::Parameter::*

Returns the portion of the command used in the <command/> block in galaxy XML files

=head2 getOptionsArray

When called on a CPT::Parameter::* object, it will collapse the object into a GetOpt::Long compatible array

=head2 getopt_identifier

Used for backwards compatability with existing defaults => { 'file|f=s' => "Blah" }  format

=head2 get_galaxy_identifier

Returns the identifier associated with a given variable. This identifier is what the Cheetah template knows the variable as (given the correct context).

For non-multiple variables it should be the name of the variable.

For multiple variables it will reference the repeat item name and then the variable name (e.g., C< $item.label >)

=head2 get_galaxy_cli_identifier

Returns the command line identifier (i.e., the command line flag) associated
with a given parameter. For a `--format` flag, this would return "format".
This should work out of the box, as CLI parameters have the same name as we
specify them with (even if they're repeated)

=head2 is_optional

If required, it is NOT optional; If not reqiured, it IS optional

=head2 is_optional_galaxy

Returns is_optional() as "True" or "False" for convenience and reduced code duplication

=head2 update_index

Convenience method to increment the index. This wraps around.

=head2 reset_index

convenience method to zero the index (i.e., the next get_value request will start at the beginning again)

=head2 get_value

Returns the value in the current index.

=head2 get_default

Returns the default in the current index. Something to note, please bear in
mind this you are trying to access an array based on an index which wraps
according to value() not according to default(). This means you may not reach
the end of default/reach over the end of default depending on how many values
the user actually passes

=head2 validate

Validation logic was eventually moved out here, as the logic for validaton is
identical everywhere, and requires slightly different behaviour based on
wheterh or not it's a single/multiple valued item.

=head2 get_repeat_idx_name

Function to obtain the name of the item as it is called inside the repeat. This
is necessary to know which variable we are referring to within a loop.

=head2 get_repeat_name

Function to obtain the name of the repeat. It is necessary that this is used
identically in the command section as well as in the input section.

=head2 handle_possible_galaxy_input_repeat_start

If the feature is repeated, this should automatically handle the start of that
repeat

=head2 handle_possible_galaxy_input_repeat_end

If the feature is repeated, this should automatically handle the end of that
repeat

=head2 handle_possible_galaxy_command_repeat_start

If the feature is repeated, this should automatically handle the start of that
repeat with a

    #for $item in $repeat_name:

=head2 handle_possible_galaxy_command_repeat_end

If the feature is repeated, this should automatically handle the end of that
repeat with

    #end for

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
