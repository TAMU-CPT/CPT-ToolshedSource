package CPT::ParameterCollection;
use Carp;
use Moose;
use strict;
use warnings;
use autodie;
use Data::Dumper;

# A collection of parameters

has 'params' => ( is => 'rw', isa => 'ArrayRef', default => sub{[]});


sub validate {
	my ( $self, $getopt_obj) = @_;
	my $issue_count = 0;
	for my $item ( @{ $self->params() } ) {
		my $type = ref($item);
		# We now check that getopt has supplied a value (we don't want to validate values that were NOT supplied. That'd be dumb)
		# If it's defined AND it doesn't validate, then we add an error on the stack for that.
		if(defined $item->name() && defined $getopt_obj->{$item->name()} && !$item->validate()){
			carp join("\n", @{$item->errors()});
			$issue_count++;
		}
	}
	return $issue_count == 0;
}



sub push_group {
	my ( $self, $group ) = @_;
	$self->push_params($group->flattenOptionsArray());
}


sub push_param {
	my ( $self, $param ) = @_;
	$self->_push($self->_coerce_param($_));
}


sub push_params {
	my ( $self, $array_ref ) = @_;
	foreach(@{$array_ref}){
		my $result = $self->_coerce_param($_);
		if($result){
			$self->_push($result);
		}
	}
}

sub _push{
	my ( $self, $array_ref ) = @_;
	my @arr;
	if($self->params()){
		@arr = @{$self->params()};
	}
	push(@arr, $array_ref);
	$self->params(\@arr);
}


sub parse_short_name {
	my ( $self, $parameter ) = @_;
	if ( index( $parameter, '|' ) > -1 ) {
		return substr( $parameter, index( $parameter, '|' ) + 1 );
	}
	else {
		return "";
	}
}


sub parse_long_name {
	my ( $self, $parameter ) = @_;
	if ( index( $parameter, '|' ) > -1 ) {
		return substr( $parameter, 0, index( $parameter, '|' ) );
	}
	else {
		return $parameter;
	}
}


sub _coerce0 {
    my ($self) = @_;
    require CPT::Parameter::Empty;
    my $p = CPT::Parameter::Empty->new();
    return $p;
}
sub _coerce1 {
	my ($self, @parts) = @_;
	require CPT::Parameter::Label;
	my $p = CPT::Parameter::Label->new(label=> $parts[0]);
	return $p;
}
sub _coerce2 {
	my ($self, @parts) = @_;
	require CPT::Parameter::Flag;
	my $p = CPT::Parameter::Flag->new(
		name        => $self->parse_long_name( $parts[0] ),
		short       => $self->parse_short_name( $parts[0] ),
		multiple    => 0,
		description => $parts[1],
	);
	return $p;
}
sub _coerce3 {
	my ($self, @parts) = @_;
	# Three parameter case
	my %attr = (
		name        => $self->parse_long_name( $parts[0] ),
		short       => $self->parse_short_name( $parts[0] ),
		multiple    => 0,
		description => $parts[1],
	);

	# create the attr
	my %set_attr = %{ $parts[2] };

	# Check if various things are set, if so, copy them.
	foreach (qw(default options required hidden implies multiple _show_in_galaxy _galaxy_specific data_format default_format file_format)) {
		if ( defined $set_attr{$_} ) {
			$attr{$_} = $set_attr{$_};
		}
	}

	# Now, if validate is set, we can choose a type and possibly do other coersion.
	if ( $set_attr{'validate'} ) {
		my $validate = $set_attr{'validate'};
		my $p;
		if ( $validate eq 'Flag' ) {
			require CPT::Parameter::Flag;
			$p = CPT::Parameter::Flag->new(%attr);
		}
		elsif ( $validate eq 'Float' ) {
			foreach (qw(min max)) {
				if ( $set_attr{$_} ) {
					$attr{$_} = $set_attr{$_};
				}
			}
			require CPT::Parameter::Float;
			$p = CPT::Parameter::Float->new(%attr);
		}
		elsif ( $validate eq 'Int' ) {
			foreach (qw(min max)) {
				if ( $set_attr{$_} ) {
					$attr{$_} = $set_attr{$_};
				}
			}
			require CPT::Parameter::Int;
			$p = CPT::Parameter::Int->new(%attr);
		}
		elsif ( $validate eq 'Option' ) {
			foreach (qw(options)) {
				if ( $set_attr{$_} ) {
					$attr{$_} = $set_attr{$_};
				}
			}
			require CPT::Parameter::Option::Generic;
			$p = CPT::Parameter::Option::Generic->new(%attr);
		}
		elsif ( $validate eq 'String' ) {
			require CPT::Parameter::String;
			$p = CPT::Parameter::String->new(%attr);
		}
		elsif ( $validate eq 'File/Input' ) {
			require CPT::Parameter::File::Input;
			$p = CPT::Parameter::File::Input->new(%attr);
		}
		elsif ( $validate eq 'File/Output' ) {
			require CPT::Parameter::File::Output;
			$p = CPT::Parameter::File::Output->new(%attr);
		}
		elsif ( $validate eq 'File/OutputFormat' ) {
			require CPT::Parameter::File::OutputFormat;
			$p = CPT::Parameter::File::OutputFormat->new(%attr);
		}
		elsif ( $validate eq 'Genomic/Tag' ) {
			require CPT::Parameter::Option::Genomic_Tag;
			$p = CPT::Parameter::Option::Genomic_Tag->new(%attr);
		}
		else {
			die 'Unknown validation type: ' . $validate;
		}
		return $p;
	}
	else {
		require CPT::Parameter::Flag;
		my $p = CPT::Parameter::Flag->new(%attr);
		return $p;
	}
}

sub _coerce_param {
	my ( $self, $param ) = @_;
	if ( ref($param) eq 'ARRAY' ) {
		my @parts = @{$param};
		if ( scalar @parts == 0 ) {
			return $self->_coerce0(@parts);
		}
		elsif ( scalar @parts == 1 ) {
			return $self->_coerce1(@parts);
		}
		elsif ( scalar @parts == 2 ) {
			return $self->_coerce2(@parts);
		}
		else {
			return $self->_coerce3(@parts);
		}
	}
	else {
		die 'A non-array type was attempted to be coerced...';
	}
}


sub get_by_name {
	my ( $self, $name ) = @_;
	for my $item ( @{ $self->params() } ) {
		if ( defined $item->name() && $item->name() eq $name ) {
			return $item;
		}
	}
	return;
}


sub getopt {
	my ($self) = @_;
	my @clean_opt_spec;

	# Loop through each item
	for my $item ( @{ $self->params() } ) {
		my $type = ref($item);

		# If it's an array, that means it's definitely an old style
		if ( $type eq 'ARRAY' ) {

			# And we can push it through without any issues
			push( @clean_opt_spec, $item );
		}

		# If it's a hash, it's probably one of the { one_of/xor/etc }
		elsif ( $type eq 'CPT::ParameterGroup' ) {

			# D:
			push( @clean_opt_spec, $item->flattenOptionsArray() );
		}

		# Otherwise it's one of our CPT::Parameter stuff
		else {

			# Otherwise, we'll use the method to transform our complex object into a GetOpt compatible item
			push( @clean_opt_spec, $item->getOptionsArray() );
		}
	}
	return @clean_opt_spec;
}


sub populate_from_getopt {
	my ( $self, $opt ) = @_;
	# Loop through each item
	for my $item ( @{ $self->params() } ) {
		# If it's has a name, and options supplies a value for that name
		if ( defined($item->name()) && defined ($opt->{$item->name()})){
			$item->value($opt->{ $item->name() });
		}
	}
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::ParameterCollection

=head1 VERSION

version 1.99.4

=head2 validate

	$pC->validate();

calls the validate method, which loops through and checks that user values line
up with the validate method in each and every slot.

=head2 push_group

	$pC->push_group(CPT::Parameter::Flag->new( <snip> ));

Push a new groupeter onto the array

=head2 push_param

	$pC->push_param(CPT::Parameter::Flag->new( <snip> ));

Push a new parameter onto the array

=head2 push_params

	$pC->push_param([
		<snip some params>
	]);

Pushes a lot of params at once onto the array

=head2 parse_short_name

	$pc->parse_short_name("file|f");
	# would return "f"

=head2 parse_long_name

	$pc->parse_long_name("file|f");
	# would return "file"

=head2 _coerce_param

	$pc->_coerce_param(["file|f","input file",{validate=>'File/Input'}]);

would return a CPT::Parameter::File::Input object.

=head2 get_by_name

	$pC->get_by_name('format');

returns the CPT::Parameter object with that key. 

=head2 getopt

	my @getopt_compatible_array = $pC->getopt()

Returns a getopt compatible array by looping through the array and simply returning array objects, and calling the getOptionsArray method on CPT::Parameter::* objects

=head2 populate_from_getopt

	$parameterCollection->populate_from_getopt($opt);

Populate the ->value() from getopt.

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
