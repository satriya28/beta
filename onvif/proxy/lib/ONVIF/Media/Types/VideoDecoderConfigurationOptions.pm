package ONVIF::Media::Types::VideoDecoderConfigurationOptions;
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

my %JpegDecOptions_of :ATTR(:get<JpegDecOptions>);
my %H264DecOptions_of :ATTR(:get<H264DecOptions>);
my %Mpeg4DecOptions_of :ATTR(:get<Mpeg4DecOptions>);
my %Extension_of :ATTR(:get<Extension>);

__PACKAGE__->_factory(
    [ qw(        JpegDecOptions
        H264DecOptions
        Mpeg4DecOptions
        Extension

    ) ],
    {
        'JpegDecOptions' => \%JpegDecOptions_of,
        'H264DecOptions' => \%H264DecOptions_of,
        'Mpeg4DecOptions' => \%Mpeg4DecOptions_of,
        'Extension' => \%Extension_of,
    },
    {
        'JpegDecOptions' => 'ONVIF::Media::Types::JpegDecOptions',
        'H264DecOptions' => 'ONVIF::Media::Types::H264DecOptions',
        'Mpeg4DecOptions' => 'ONVIF::Media::Types::Mpeg4DecOptions',
        'Extension' => 'ONVIF::Media::Types::VideoDecoderConfigurationOptionsExtension',
    },
    {

        'JpegDecOptions' => 'JpegDecOptions',
        'H264DecOptions' => 'H264DecOptions',
        'Mpeg4DecOptions' => 'Mpeg4DecOptions',
        'Extension' => 'Extension',
    }
);

} # end BLOCK








1;


=pod

=head1 NAME

ONVIF::Media::Types::VideoDecoderConfigurationOptions

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
VideoDecoderConfigurationOptions from the namespace http://www.onvif.org/ver10/schema.






=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * JpegDecOptions


=item * H264DecOptions


=item * Mpeg4DecOptions


=item * Extension




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # ONVIF::Media::Types::VideoDecoderConfigurationOptions
   JpegDecOptions =>  { # ONVIF::Media::Types::JpegDecOptions
     ResolutionsAvailable =>  { # ONVIF::Media::Types::VideoResolution
       Width =>  $some_value, # int
       Height =>  $some_value, # int
     },
     SupportedInputBitrate =>  { # ONVIF::Media::Types::IntRange
       Min =>  $some_value, # int
       Max =>  $some_value, # int
     },
     SupportedFrameRate =>  { # ONVIF::Media::Types::IntRange
       Min =>  $some_value, # int
       Max =>  $some_value, # int
     },
   },
   H264DecOptions =>  { # ONVIF::Media::Types::H264DecOptions
     ResolutionsAvailable =>  { # ONVIF::Media::Types::VideoResolution
       Width =>  $some_value, # int
       Height =>  $some_value, # int
     },
     SupportedH264Profiles => $some_value, # H264Profile
     SupportedInputBitrate =>  { # ONVIF::Media::Types::IntRange
       Min =>  $some_value, # int
       Max =>  $some_value, # int
     },
     SupportedFrameRate =>  { # ONVIF::Media::Types::IntRange
       Min =>  $some_value, # int
       Max =>  $some_value, # int
     },
   },
   Mpeg4DecOptions =>  { # ONVIF::Media::Types::Mpeg4DecOptions
     ResolutionsAvailable =>  { # ONVIF::Media::Types::VideoResolution
       Width =>  $some_value, # int
       Height =>  $some_value, # int
     },
     SupportedMpeg4Profiles => $some_value, # Mpeg4Profile
     SupportedInputBitrate =>  { # ONVIF::Media::Types::IntRange
       Min =>  $some_value, # int
       Max =>  $some_value, # int
     },
     SupportedFrameRate =>  { # ONVIF::Media::Types::IntRange
       Min =>  $some_value, # int
       Max =>  $some_value, # int
     },
   },
   Extension =>  { # ONVIF::Media::Types::VideoDecoderConfigurationOptionsExtension
   },
 },




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

