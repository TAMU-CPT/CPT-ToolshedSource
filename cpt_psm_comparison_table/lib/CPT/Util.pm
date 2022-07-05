package CPT::Util;
use strict;
use warnings;
use Moose;

#ABSTRACT: CPT convenience functions



sub JSONYAMLopts {
    my ( $self, %data ) = @_;
    my %hash;
    if ( $data{'file'} ) {
       my $ext = substr($data{'file'}, rindex($data{'file'}, '.') + 1);
       if ( lc $ext eq 'yaml' || lc $ext eq 'yml' ) {
           require YAML::XS;
           %hash = %{ YAML::XS::LoadFile( $data{'file'} ) };
       }
       elsif ( lc $ext eq 'json' ) {
           require JSON::XS;
           require File::Slurp;
           my $json = File::Slurp::read_file( $data{'file'} );
           %hash = %{ JSON::XS::decode_json($json) };
       }
       else {
           confess "Requested JSON/YAML file lacked a recognisable suffix $ext";
       }
    }
    else {
        confess 'Error, no options provided';
    }
    return \%hash;

}



sub untaint_path {
    delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };
    $ENV{'PATH'} = '/bin:/usr/bin';
    my $path = $ENV{'PATH'};
    return 1;
}



no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPT::Util - CPT convenience functions

=head1 VERSION

version 1.99.4

=head1 FUNCTIONAL INTERFACE

    my $libCPT = CPT::CPT->new();

=head2 JSONYAMLopts

    my %colour_options = %{
        $libCPT->JSONYAMLopts(
            'file'=>$options{'optionsfile'},
            'string'=> $options{'optionsstring'}
        )
    };

Reads from a file or from a string passed to it describing additional options in JSON or YAML. (Should I support other options?)

For scripts that require significant numbers of input parameters where they are often re-used, it isn't sensible to require people to specify ten flags on the command line. Offering a JSON/YAML file reader simplifies their life by providing re-usable config files.

=head2 untaint_path

    $libCPT->untaint_path();

Convenience function

=head1 AUTHOR

Eric Rasche <rasche.eric@yandex.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Eric Rasche.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
