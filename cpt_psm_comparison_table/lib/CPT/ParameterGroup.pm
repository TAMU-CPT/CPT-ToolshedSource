package CPT::ParameterGroup;
use Moose;
use strict;
use warnings;
use autodie;

# A special type of a ParameterCollection (could probably be a child...ohwell)
use Moose::Util::TypeConstraints;
#subtype 'TypeStr', as 'Str', where { $_ eq 'xor' || $_ eq 'or' || $_ eq 'and' };
# Replaced with the enum

has 'name' => ( is => 'rw', isa => 'Str');
has 'description' => ( is => 'rw', isa => 'Str');
has 'validator' => ( is => 'rw', isa => enum([qw(xor or and)]));
has 'options' => ( is => 'rw', isa => 'ArrayRef[HashRef]' );


sub validate {
	die 'Unimplemented';
}



sub set_data {
	my ($self, $hash_ref) = @_;
	my %d = %{$hash_ref};
	$self->name($d{name});
	$self->description($d{description});
	$self->validator($d{validator});
	$self->options($d{options});
}



sub getopt {
	my ($self) = @_;
	die 'unimplemented';
}

sub flattenOptionsArray{
	my ($self) = @_;
	my @opts;
	push(@opts, [sprintf("Option Group: %s\n%s\n[%s]", $self->name(), $self->description(), $self->_formatted_choice_str)]);
	require CPT::ParameterCollection;
	my $pC = CPT::ParameterCollection->new();
	foreach(@{$self->options()}){
		my %z = %{$_};
		my $group_name = $z{group};
		my @group_opts = @{$z{options}};
		push(@opts, [sprintf("Subgroup: %s", $group_name)]);
		foreach(@group_opts){
			my $p = $pC->_coerce_param($_);
			push(@opts, $p->getOptionsArray());
		}
	}
	return \@opts;
}

sub _formatted_choice_str{
	my ($self) = @_;
	if($self->validator() eq 'xor'){
		return 'Please only use options from ONE of the groups below, and no more';
	}elsif($self->validator() eq 'or'){
		return 'Please only use options from at least ONE of the groups below';
	}elsif($self->validator() eq 'and'){
		return 'Please ensure values/defaults are specified for ALL of the options in the groups below';
	}
	return undef;
}


sub populate_from_getopt {
	my ( $self, $opt ) = @_;
	die 'unimplemented';
}

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::ParameterGroup

=head1 VERSION

version 1.99.4

=head2 validate

	$pC->validate();

calls the validate method, which loops through and checks that user values line up with the validate method in each and every slot.

Currently unimplemented!

=head2 getopt

	my @getopt_compatible_array = $pC->getopt()

Returns a getopt compatible array by looping through the array and simply returning array objects, and calling the getOptionsArray method on CPT::Parameter::* objects

=head2 populate_from_getopt

	$parameterCollection->populate_from_getopt($opt);

Populate the ->value() from getopt. This is the special sauce of this portion of the module. 
Our test case for this function is the connector choice problem.

{ 
        name => 'Data Source #1',
        description => "FASTA data source for our script",
        type => 'xor', # must select only from one subgroup
        options => [
            {
                group => 'Chado Custom',
                options => [
                    [ 'host' => 'Hostname', { required => 1, validate => 'Str' } ],
                    [ 'user' => 'Username', { required => 1, validate => 'Str' } ],
                    [ 'pass' => 'Password', { required => 1, validate => 'Str' } ],
                    [ 'name' => 'Database name', { required => 1, validate => 'Str' } ],
                    [ 'organism' => 'organism name', { required => 1, validate => 'Str' } ],
                    [ 'landmark' => 'landmark name', { required => 1, validate => 'Str' } ],
                ]
            },
            {
                group => 'Chado GMOD pre-defined connector',
                options => [
                    [ 'conn=s' => 'Connection Nickname', { required => 1, validate => 'Str' } ],
                ]
            },
            {
                group => 'File',
                options => [
                    [ 'file|f=' => 'Input file', { required => 1, validate => 'File/Input' } ],
                ]
            },

        ]
    },

This should intelligently set parameters in $opt based on the passed data. The real question is how to handle password....

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
