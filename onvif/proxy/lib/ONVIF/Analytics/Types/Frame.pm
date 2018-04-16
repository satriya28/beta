package ONVIF::Analytics::Types::Frame;
use strict;
use warnings;


__PACKAGE__->_set_element_form_qualified(1);

sub get_xmlns { 'http://www.onvif.org/ver10/schema' };

our $XML_ATTRIBUTE_CLASS = 'ONVIF::Analytics::Types::Frame::_Frame::XmlAttr';

sub __get_attr_class {
    return $XML_ATTRIBUTE_CLASS;
}

use Class::Std::Fast::Storable constructor => 'none';
use base qw(SOAP::WSDL::XSD::Typelib::ComplexType);

Class::Std::initialize();

{ # BLOCK to scope variables

my %PTZStatus_of :ATTR(:get<PTZStatus>);
my %Transformation_of :ATTR(:get<Transformation>);
my %Object_of :ATTR(:get<Object>);
my %ObjectTree_of :ATTR(:get<ObjectTree>);
my %Extension_of :ATTR(:get<Extension>);

__PACKAGE__->_factory(
    [ qw(        PTZStatus
        Transformation
        Object
        ObjectTree
        Extension

    ) ],
    {
        'PTZStatus' => \%PTZStatus_of,
        'Transformation' => \%Transformation_of,
        'Object' => \%Object_of,
        'ObjectTree' => \%ObjectTree_of,
        'Extension' => \%Extension_of,
    },
    {
        'PTZStatus' => 'ONVIF::Analytics::Types::PTZStatus',
        'Transformation' => 'ONVIF::Analytics::Types::Transformation',
        'Object' => 'ONVIF::Analytics::Types::Object',
        'ObjectTree' => 'ONVIF::Analytics::Types::ObjectTree',
        'Extension' => 'ONVIF::Analytics::Types::FrameExtension',
    },
    {

        'PTZStatus' => 'PTZStatus',
        'Transformation' => 'Transformation',
        'Object' => 'Object',
        'ObjectTree' => 'ObjectTree',
        'Extension' => 'Extension',
    }
);

} # end BLOCK




package ONVIF::Analytics::Types::Frame::_Frame::XmlAttr;
use base qw(SOAP::WSDL::XSD::Typelib::AttributeSet);

{ # BLOCK to scope variables

my %UtcTime_of :ATTR(:get<UtcTime>);

__PACKAGE__->_factory(
    [ qw(
        UtcTime
    ) ],
    {

        UtcTime => \%UtcTime_of,
    },
    {
        UtcTime => 'SOAP::WSDL::XSD::Typelib::Builtin::dateTime',
    }
);

} # end BLOCK




1;


=pod

=head1 NAME

ONVIF::Analytics::Types::Frame

=head1 DESCRIPTION

Perl data type class for the XML Schema defined complexType
Frame from the namespace http://www.onvif.org/ver10/schema.






=head2 PROPERTIES

The following properties may be accessed using get_PROPERTY / set_PROPERTY
methods:

=over

=item * PTZStatus


=item * Transformation


=item * Object


=item * ObjectTree


=item * Extension




=back


=head1 METHODS

=head2 new

Constructor. The following data structure may be passed to new():

 { # ONVIF::Analytics::Types::Frame
   PTZStatus =>  { # ONVIF::Analytics::Types::PTZStatus
     Position =>  { # ONVIF::Analytics::Types::PTZVector
       PanTilt => ,
       Zoom => ,
     },
     MoveStatus =>  { # ONVIF::Analytics::Types::PTZMoveStatus
       PanTilt => $some_value, # MoveStatus
       Zoom => $some_value, # MoveStatus
     },
     Error =>  $some_value, # string
     UtcTime =>  $some_value, # dateTime
   },
   Transformation =>  { # ONVIF::Analytics::Types::Transformation
     Translate => ,
     Scale => ,
     Extension =>  { # ONVIF::Analytics::Types::TransformationExtension
     },
   },
   Object =>  { # ONVIF::Analytics::Types::Object
     Appearance =>  { # ONVIF::Analytics::Types::Appearance
       Transformation =>  { # ONVIF::Analytics::Types::Transformation
         Translate => ,
         Scale => ,
         Extension =>  { # ONVIF::Analytics::Types::TransformationExtension
         },
       },
       Shape =>  { # ONVIF::Analytics::Types::ShapeDescriptor
         BoundingBox => ,
         CenterOfGravity => ,
         Polygon =>  { # ONVIF::Analytics::Types::Polygon
           Point => ,
         },
         Extension =>  { # ONVIF::Analytics::Types::ShapeDescriptorExtension
         },
       },
       Color =>  { # ONVIF::Analytics::Types::ColorDescriptor
         ColorCluster =>  {
           Color => ,
           Weight =>  $some_value, # float
           Covariance => ,
         },
         Extension =>  { # ONVIF::Analytics::Types::ColorDescriptorExtension
         },
       },
       Class =>  { # ONVIF::Analytics::Types::ClassDescriptor
         ClassCandidate =>  {
           Type => $some_value, # ClassType
           Likelihood =>  $some_value, # float
         },
         Extension =>  { # ONVIF::Analytics::Types::ClassDescriptorExtension
           OtherTypes =>  { # ONVIF::Analytics::Types::OtherType
             Type =>  $some_value, # string
             Likelihood =>  $some_value, # float
           },
           Extension =>  { # ONVIF::Analytics::Types::ClassDescriptorExtension2
           },
         },
       },
       Extension =>  { # ONVIF::Analytics::Types::AppearanceExtension
       },
     },
     Behaviour =>  { # ONVIF::Analytics::Types::Behaviour
       Removed =>  {
       },
       Idle =>  {
       },
       Extension =>  { # ONVIF::Analytics::Types::BehaviourExtension
       },
     },
     Extension =>  { # ONVIF::Analytics::Types::ObjectExtension
     },
   },
   ObjectTree =>  { # ONVIF::Analytics::Types::ObjectTree
     Rename =>  { # ONVIF::Analytics::Types::Rename
       from => ,
       to => ,
     },
     Split =>  { # ONVIF::Analytics::Types::Split
       from => ,
       to => ,
     },
     Merge =>  { # ONVIF::Analytics::Types::Merge
       from => ,
       to => ,
     },
     Delete => ,
     Extension =>  { # ONVIF::Analytics::Types::ObjectTreeExtension
     },
   },
   Extension =>  { # ONVIF::Analytics::Types::FrameExtension
     MotionInCells =>  { # ONVIF::Analytics::Types::MotionInCells
     },
     Extension =>  { # ONVIF::Analytics::Types::FrameExtension2
     },
   },
 },



=head2 attr

NOTE: Attribute documentation is experimental, and may be inaccurate.
See the correspondent WSDL/XML Schema if in question.

This class has additional attributes, accessibly via the C<attr()> method.

attr() returns an object of the class ONVIF::Analytics::Types::Frame::_Frame::XmlAttr.

The following attributes can be accessed on this object via the corresponding
get_/set_ methods:

=over

=item * UtcTime



This attribute is of type L<SOAP::WSDL::XSD::Typelib::Builtin::dateTime|SOAP::WSDL::XSD::Typelib::Builtin::dateTime>.


=back




=head1 AUTHOR

Generated by SOAP::WSDL

=cut

