package CPT::Circos::Conf;
use strict;
use warnings;
use autodie;
use Moose;

# This parameter specifies that we should behave according to galaxy_override spec.
has data => (
	is	    => 'rw',
	isa 	=> 'ArrayRef',
	default => sub {
		[]
	},
);
my @current_block = ();

sub set {
	my ($self, $key, $value) = @_;
	$self->push_d(sprintf('%s = %s', $key, $value));
}

sub start_block {
	my ($self, $block) = @_;
	$self->push_d(sprintf('<%s>', $block));
	push(@current_block, $block);
}

sub end_block {
	my ($self) = @_;
	$self->push_d(sprintf('</%s>', pop @current_block));
}

sub include {
	my ($self, $file) = @_;
	$self->push_d(sprintf('<<include %s>>', $file));
}

sub push_d {
	my ($self, $string) = @_;
	push(@{$self->data()}, $self->spaces_for_indent() . $string);
}

sub spaces_for_indent {
	my ($self) = @_;
	if(scalar(@current_block) > 0){
		return '  ' x scalar(@current_block);
	}
	return '';
}

sub finalize {
	my ($self) = @_;
	if(scalar @current_block > 0){
		die  'Blocks [' . join(',', @current_block) . '] were not closed';
	}
	else{
		return join("\n", @{$self->data()});
	}
}

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Circos::Conf

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
