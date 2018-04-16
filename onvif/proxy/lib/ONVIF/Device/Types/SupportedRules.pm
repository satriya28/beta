package ONVIF::Device::Types::SupportedRules;
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

my %RuleContentSchemaLocation_of :ATTR(:get<RuleContentSchemaLocation>);
my %RuleDescription_of :ATTR(:get<RuleDescription>);
my %Extension_of :ATTR(:get<Extension>);

__PACKAGE__->_factory(
    [ qw(        RuleContentSchemaLocation
        RuleDescription
        Extension

    ) ],
    {
        'RuleContentSchemaLocation' => \%RuleContentSchemaLocation_of,
        'RuleDescription' => \%RuleDescription_of,
        'Extension' => \%Extension_of,
    },
    {
        'RuleContentSchemaLocation' => 'SOAP::WSDL::XSD::Typelib::Builtin::anyURI',
        'RuleDescription' => 'ONVIF::Device::Types::ConfigDescription',
        'Extension' => 'ONVIF::Device::Types::SupportedRulesExtension',
    },
    {

        'RuleContentSchemaLocation' => 'RuleContentSchemaLocation',
        'RuleDescription' => 'RuleDescription',
        'Extension' => 'Extension',
    }
);

} # end BLOCK








1;


=pod

=head1 NAME

ONVIF::Device::Types::SupportedRules

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
SupportedRules from the namespace http://www.onvif.org/ver10/schema.






=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * RuleContentSchemaLocation


=item * RuleDescription


=item * Extension




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # ONVIF::Device::Types::SupportedRules
   RuleContentSchemaLocation =>  $some_value, # anyURI
   RuleDescription =>  { # ONVIF::Device::Types::ConfigDescription
     Parameters =>  { # ONVIF::Device::Types::ItemListDescription
       SimpleItemDescription => ,
       ElementItemDescription => ,
       Extension =>  { # ONVIF::Device::Types::ItemListDescriptionExtension
       },
     },
     Messages =>  {
       ParentTopic =>  $some_value, # string
     },
     Extension =>  { # ONVIF::Device::Types::ConfigDescriptionExtension
     },
   },
   Extension =>  { # ONVIF::Device::Types::SupportedRulesExtension
   },
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

