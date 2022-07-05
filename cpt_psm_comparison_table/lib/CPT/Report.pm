package CPT::Report;
use Moose::Role;
use strict;
use warnings;
use autodie;

requires 'header';
requires 'footer';
requires 'h1';
requires 'h2';
requires 'h3';
requires 'h4';
requires 'h5';
requires 'h6';
requires 'p';
requires 'list_start';
requires 'list_end';
requires 'list_element';

has 'title'  => ( is => 'rw', isa => 'Str' );
has 'date'   => ( is => 'rw', isa => 'Str');
has 'author' => ( is => 'rw', isa => 'Str' );
# Core content that we build up.
has 'content' => ( is => 'rw', isa => 'Str', default => "");

# Internal
has '_list_type' => ( is => 'rw', isa => 'Str', default => 'bullet');

sub a{
	my ($self, $addition) = @_;
	$self->content($self->content() . $addition);
}

sub get_content{
	my ($self) = @_;
	return $self->header() . $self->content() . $self->footer();
}

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Report

=head1 VERSION

version 1.99.4

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
