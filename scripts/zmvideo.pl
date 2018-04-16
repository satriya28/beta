#!/usr/bin/perl -wT
#
# ==========================================================================
#
# ZoneMinder Video Creation Script, $Date$, $Revision$
# Copyright (C) 2001-2008 Philip Coombes
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# ==========================================================================

=head1 NAME

zmvideo.pl - ZoneMinder Video Creation Script

=head1 SYNOPSIS

 zmvideo.pl [ -e <event_id>,--event=<event_id> | --filter=<filter name> ] [--format <format>]
                                             [--rate=<rate>]
                                             [--scale=<scale>]
                                             [--fps=<fps>]
                                             [--size=<size>]
                                             [--overwrite]

=head1 DESCRIPTION

This script is used to create MPEG videos of events for the web pages
or as email attachments.

=head1 OPTIONS
 -c[=filename], --concat[=filename] - When creating videos for multiple events, create a concatenated video as well.
                                    - If not specified, filename is taken from filter name.
 -e<event_id>, --event=<event_id>   - What event to create the video for
 --filter_name=<filter name>        - The name of a saved filter to generate a video for all events returned by it.
 --filter_id=<filter id>            - The id of a saved filter to generate a video for all events returned by it.
 -f<format>, --format=<format>      - What format to create the video in, default is mpg. For ffmpeg only.
 -r<rate>, --rate=<rate>            - Relative rate, 1 = realtime, 2 = double speed, 0.5 = half speed etc.
 -s<scale>, --scale=<scale>         - Scale, 1 = normal, 2 = double size, 0.5 = half size etc.
 -F<fps>, --fps=<fps>               - Absolute frame rate, in frames per second
 -S<size>, --size=<size>            - Absolute video size, WxH or other specification supported by ffmpeg
 -o, --overwrite                    - Whether to overwrite an existing file, off by default.
 -v, --version                      - Outputs the currently installed version of ZoneMinder

=cut
use strict;
use bytes;

# ==========================================================================
#
# You shouldn't need to change anything from here downwards
#
# ==========================================================================

# Include from system perl paths only
use ZoneMinder;
require ZoneMinder::Filter;
require ZoneMinder::Event;
use DBI;
use autouse 'Data::Dumper'=>qw(Dumper);
use POSIX qw(strftime);
use Getopt::Long qw(:config no_ignore_case );
use Cwd;
use autouse 'Pod::Usage'=>qw(pod2usage);

$| = 1;

$ENV{PATH}  = '/bin:/usr/bin:/usr/local/bin';
$ENV{SHELL} = '/bin/sh' if exists $ENV{SHELL};
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

logInit();

my $event_id;
my $concat_name;
my $filter_name;
my $filter_id;
my $format = 'mpg';
my $rate = '';
my $scale = '';
my $fps = '';
my $size = '';
my $overwrite = 0;
my $version = 0;

my @formats = split( /\s+/, $Config{ZM_FFMPEG_FORMATS} );
for ( my $i = 0; $i < @formats; $i++ )
{
    if ( $i =~ /^(.+)\*$/ )
    {
        $format = $formats[$i] = $1;
    }
}

GetOptions(
	'concat|c:s'	=>\$concat_name,
    'event|e=i'     =>\$event_id,
    'filter_name=s'	=>\$filter_name,
    'filter_id=i'	=>\$filter_id,
    'format|f=s'    =>\$format,
    'rate|r=f'      =>\$rate,
    'scale|s=f'     =>\$scale,
    'fps|F=f'       =>\$fps,
    'size|S=s'      =>\$size,
    'overwrite'     =>\$overwrite,
    'version'       =>\$version
) or pod2usage(-exitstatus => -1);

if ( $version ) {
    print ZoneMinder::Base::ZM_VERSION . "\n";
    exit(0);
}

if ( !( $filter_id or $filter_name or $event_id ) || $event_id < 0 )
{
    print( STDERR "Please give a valid event id or filter name\n" );
    pod2usage(-exitstatus => -1);
}

if ( ! $Config{ZM_OPT_FFMPEG} )
{
    print( STDERR "Mpeg encoding is not currently enabled\n" );
    exit(-1);
}

if ( !$rate && !$fps )
{
    $rate = 1;
}

if ( !$scale && !$size )
{
    $scale = 1;
}

if ( $rate && ($rate < 0.25 || $rate > 100) )
{
    print( STDERR "Rate is out of range, 0.25 >= rate <= 100\n" );
    pod2usage(-exitstatus => -1);
}

if ( $scale && ($scale < 0.25 || $scale > 4) )
{
    print( STDERR "Scale is out of range, 0.25 >= scale <= 4\n" );
    pod2usage(-exitstatus => -1);
}

if ( $fps && ($fps > 30) )
{
    print( STDERR "FPS is out of range, <= 30\n" );
    pod2usage(-exitstatus => -1);
}

my ( $detaint_format ) = $format =~ /^(\w+)$/;
my ( $detaint_rate ) = $rate =~ /^(-?\d+(?:\.\d+)?)$/;
my ( $detaint_scale ) = $scale =~ /^(-?\d+(?:\.\d+)?)$/;
my ( $detaint_fps ) = $fps =~ /^(-?\d+(?:\.\d+)?)$/;
my ( $detaint_size ) = $size =~ /^(\w+)$/;

$format = $detaint_format;
$rate = $detaint_rate;
$scale = $detaint_scale;
$fps = $detaint_fps;
$size = $detaint_size;

my $dbh = zmDbConnect();

my $cwd = getcwd;

my $video_name;
my @event_ids;
if ( $event_id ) {
	@event_ids = ( $event_id );
	
} elsif ( $filter_name or $filter_id ) {
	my $Filter = ZoneMinder::Filter->find_one( 
		($filter_name ? ( Name => $filter_name ) : () ),
		($filter_id ? ( Id => $filter_name ) : () ),
		);
	if ( ! $Filter ) {
		Fatal("Filter $filter_name $filter_id not found.");	
	}	
	@event_ids = map { $_->{Id} }$Filter->Execute();	
	Fatal( "No events found for $filter_name") if ! @event_ids;
	$concat_name = $filter_name if $concat_name eq '';
}

my $sql = " SELECT max(F.Delta)-min(F.Delta) as FullLength,
   E.*,
   unix_timestamp(E.StartTime) as Time,
   M.Name as MonitorName,
   M.Width as MonitorWidth,
   M.Height as MonitorHeight,
   M.Palette
   FROM Frames as F
   INNER JOIN Events as E on F.EventId = E.Id
   INNER JOIN Monitors as M on E.MonitorId = M.Id
   WHERE EventId = ?
   GROUP BY F.EventId"
   ;
my $sth = $dbh->prepare_cached( $sql ) or Fatal( "Can't prepare '$sql': ".$dbh->errstr() );

my @video_files;
foreach my $event_id ( @event_ids ) {

	my $res = $sth->execute( $event_id )
		or Fatal( "Can't execute: ".$sth->errstr() );
	my $event = $sth->fetchrow_hashref();

	my $Event = new ZoneMinder::Event( $$event{Id}, $event );
	my $video_file = $Event->GenerateVideo( $rate, $fps, $scale,  $size, $overwrite, $format );
	if ( $video_file ) {
		push @video_files, $video_file;
		print( STDOUT $video_file."\n" );
	}
} # end foreach event_id

if ( $concat_name ) {
	($cwd) = $cwd =~ /(.*)/; # detaint
	chdir( $cwd );
	($concat_name ) = $concat_name =~ /([\-A-Za-z0-9_\.]*)/;
	my $concat_list_file = "/tmp/$concat_name.concat.lst";

	my $video_file = $concat_name . '.'. $detaint_format;

	open( my $fd, '>', $concat_list_file ) or die "Can't open $concat_list_file: $!";
	foreach ( @video_files ) {
		print $fd "file '$_'\n";
	}
	close $fd;
	my $command = $Config{ZM_PATH_FFMPEG}
	. " -f concat -i $concat_list_file -c copy "
		." '$video_file' > ffmpeg.log 2>&1"
		;
	Debug( $command."\n" );
	my $output = qx($command);

	my $status = $? >> 8;

	unlink $concat_list_file;
	if ( $status )
	{
		Error( "Unable to generate video, check /ffmpeg.log for details");
		exit(-1);
	}
	print( STDOUT $video_file."\n" );
}
exit( 0 );
