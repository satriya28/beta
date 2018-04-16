package ONVIF::Analytics::Types::WideDynamicRangeOptions;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'http://www.onvif.org/ver10/schema' };

our $XML_ATTRIBUTE_CLASS;
undef $XML_ATTRIBUTE_CLASS;

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %Mode_of :ATTR(:get<Mode>);
my %Level_of :ATTR(:get<Level>);

__PACKAGE__->_factory(
    [ qw(        Mode
        Level

    ) ],
    {
        'Mode' => \%Mode_of,
        'Level' => \%Level_of,
    },
    {
        'Mode' => 'ONVIF::Analytics::Types::WideDynamicMode',
        'Level' => 'ONVIF::Analytics::Types::FloatRange',
    },
    {

        'Mode' => 'Mode',
        'Level' => 'Level',
    }
);

} # end BLOCK








1;


=pod

=head1 NAME

ONVIF::Analytics::Types::WideDynamicRangeOptions

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
WideDynamicRangeOptions from the namespace http://www.onvif.org/ver10/schema.






=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * Mode


=item * Level




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # ONVIF::Analytics::Types::WideDynamicRangeOptions
   Mode => $some_value, # WideDynamicMode
   Level =>  { # ONVIF::Analytics::Types::FloatRange
     Min =>  $some_value, # float
     Max =>  $some_value, # float
   },
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

