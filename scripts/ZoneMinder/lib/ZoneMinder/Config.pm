# ==========================================================================
#
# ZoneMinder Config Module, $Date$, $Revision$
# Copyright (C) 2001-2008  Philip Coombes
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
#
# This module contains the common definitions and functions used by the rest
# of the ZoneMinder scripts
#
package ZoneMinder::Config;

use 5.006;
use strict;
use warnings;

require Exporter;
require ZoneMinder::Base;
use ZoneMinder::ConfigData qw(:all);

our @ISA = qw(Exporter ZoneMinder::Base);

use vars qw( %Config );
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration   use ZoneMinder ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our @EXPORT_CONFIG = qw( %Config ); # Get populated by BEGIN

our %EXPORT_TAGS = (
    functions => [ qw(
      zmConfigLoad
      loadConfigFromDB
      saveConfigToDB
      ) ],
    constants => [ qw(
      ZM_PID
      ) ]
    );
push( @{$EXPORT_TAGS{config}}, @EXPORT_CONFIG );
push( @{$EXPORT_TAGS{all}}, @{$EXPORT_TAGS{$_}} ) foreach keys %EXPORT_TAGS;

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = $ZoneMinder::Base::VERSION;

use constant ZM_PID => "/var/run/zm/zm.pid"; # Path to the ZoneMinder run pid file
use constant ZM_CONFIG => "/etc/zm.conf"; # Path to the ZoneMinder config file

use Carp;

# Load the config from the database into the symbol table
BEGIN {
  my $config_file = ZM_CONFIG;
  open( my $CONFIG, "<", $config_file )
    or croak( "Can't open config file '$config_file': $!" );
  foreach my $str ( <$CONFIG> ) {
    next if ( $str =~ /^\s*$/ );
    next if ( $str =~ /^\s*#/ );
    my ( $name, $value ) = $str =~ /^\s*([^=\s]+)\s*=\s*(.*?)\s*$/;
    if ( ! $name ) {
      print( STDERR "Warning, bad line in $config_file: $str\n" );
      next;
    } # end if
    $name =~ tr/a-z/A-Z/;
    $Config{$name} = $value;
  }
  close( $CONFIG );

  use DBI;
  my $socket;
  my ( $host, $portOrSocket ) = ( $Config{ZM_DB_HOST} =~ /^([^:]+)(?::(.+))?$/ );

  if ( defined($portOrSocket) ) {
    if ( $portOrSocket =~ /^\// ) {
      $socket = ";mysql_socket=".$portOrSocket;
    } else {
      $socket = ";host=".$host.";port=".$portOrSocket;
    }
  } else {
    $socket = ";host=".$Config{ZM_DB_HOST}; 
  }
  my $dbh = DBI->connect( "DBI:mysql:database=".$Config{ZM_DB_NAME}
      .$socket
      , $Config{ZM_DB_USER}
      , $Config{ZM_DB_PASS}
      ) or croak( "Can't connect to db" );
  my $sql = 'select * from Config';
  my $sth = $dbh->prepare_cached( $sql ) or croak( "Can't prepare '$sql': ".$dbh->errstr() );
  my $res = $sth->execute() or croak( "Can't execute: ".$sth->errstr() );
  while( my $config = $sth->fetchrow_hashref() ) {
    $Config{$config->{Name}} = $config->{Value};
  }
  $sth->finish();
#$dbh->disconnect();
  if ( ! exists $Config{ZM_SERVER_ID} ) {
    $Config{ZM_SERVER_ID} = undef;
    $sth = $dbh->prepare_cached( 'SELECT * FROM Servers WHERE Name=?' );
    if ( $Config{ZM_SERVER_NAME} ) {
      $res = $sth->execute( $Config{ZM_SERVER_NAME} );
      my $result = $sth->fetchrow_hashref();
      $Config{ZM_SERVER_ID} = $$result{Id};
    } elsif ( $Config{ZM_SERVER_HOST} ) {
      $res = $sth->execute( $Config{ZM_SERVER_HOST} );
      my $result = $sth->fetchrow_hashref();
      $Config{ZM_SERVER_ID} = $$result{Id};
    }
    $sth->finish();
  }
} # end BEGIN

sub loadConfigFromDB {
  print( "Loading config from DB\n" );
  my $dbh = ZoneMinder::Database::zmDbConnect();
  if ( !$dbh ) {
    print( "Error: unable to load options from database: $DBI::errstr\n" );
    return( 0 );
  }
  my $sql = "select * from Config";
  my $sth = $dbh->prepare_cached( $sql )
    or croak( "Can't prepare '$sql': ".$dbh->errstr() );
  my $res = $sth->execute()
    or croak( "Can't execute: ".$sth->errstr() );
  my $option_count = 0;
  while( my $config = $sth->fetchrow_hashref() ) {
    my ( $name, $value ) = ( $config->{Name}, $config->{Value} );
#print( "Name = '$name'\n" );
    my $option = $options_hash{$name};
    if ( !$option ) {
      warn( "No option '$name' found, removing.\n" );
      next;
    }
#next if ( $option->{category} eq 'hidden' );
    if ( defined($value) ) {
      if ( $option->{type} == $types{boolean} ) {
        $option->{value} = $value?"yes":"no";
      } else {
        $option->{value} = $value;
      }
    }
    $option_count++;;
  }
  $sth->finish();
  return( $option_count );
} # end sub loadConfigFromDB

sub saveConfigToDB {
  print( "Saving config to DB\n" );
  my $dbh = ZoneMinder::Database::zmDbConnect();
  if ( !$dbh ) {
    print( "Error: unable to save options to database: $DBI::errstr\n" );
    return( 0 );
  }

  my $ac = $dbh->{AutoCommit};
  $dbh->{AutoCommit} = 0;

  $dbh->do('LOCK TABLE Config WRITE')
    or croak( "Can't lock Config table: " . $dbh->errstr() );

  my $sql = "delete from Config";
  my $res = $dbh->do( $sql )
    or croak( "Can't do '$sql': ".$dbh->errstr() );

  $sql = "replace into Config set Id = ?, Name = ?, Value = ?, Type = ?, DefaultValue = ?, Hint = ?, Pattern = ?, Format = ?, Prompt = ?, Help = ?, Category = ?, Readonly = ?, Requires = ?";
  my $sth = $dbh->prepare_cached( $sql )
    or croak( "Can't prepare '$sql': ".$dbh->errstr() );
  foreach my $option ( @options ) {
#next if ( $option->{category} eq 'hidden' );
#print( $option->{name}."\n" ) if ( !$option->{category} );
    $option->{db_type} = $option->{type}->{db_type};
    $option->{db_hint} = $option->{type}->{hint};
    $option->{db_pattern} = $option->{type}->{pattern};
    $option->{db_format} = $option->{type}->{format};
    if ( $option->{db_type} eq "boolean" ) {
      $option->{db_value} = ($option->{value} eq "yes") ? "1" : "0";
    } else {
      $option->{db_value} = $option->{value};
    }
    if ( my $requires = $option->{requires} ) {
      $option->{db_requires} = join( ";",
          map {
            my $value = $_->{value};
            $value = ($value eq "yes") ? 1 : 0 if ( $options_hash{$_->{name}}->{db_type} eq "boolean" );
            ( "$_->{name}=$value" )
          } @$requires
          );
    }
    my $res = $sth->execute(
        $option->{id},
        $option->{name},
        $option->{db_value},
        $option->{db_type},
        $option->{default},
        $option->{db_hint},
        $option->{db_pattern},
        $option->{db_format},
        $option->{description},
        $option->{help},
        $option->{category},
        $option->{readonly} ? 1 : 0,
        $option->{db_requires}
        ) or croak( "Can't execute: ".$sth->errstr() );
  } # end foreach option
  $sth->finish();

  $dbh->do('UNLOCK TABLES');
  $dbh->{AutoCommit} = $ac;
} # end sub saveConfigToDB

1;
__END__

=head1 NAME

ZoneMinder::Config - ZoneMinder configuration module.

=head1 SYNOPSIS

use ZoneMinder::Config qw(:all);

=head1 DESCRIPTION

The ZoneMinder::Config module is used to import the ZoneMinder
configuration from the database. It will do this at compile time in a BEGIN
block and require access to the zm.conf file either in the current
directory or in its defined location in order to determine database access
details, configuration from this file will also be included. If the :all or
:config tags are used then this configuration is exported into the
namespace of the calling program or module.

Once the configuration has been imported then configuration variables are
defined as constants and can be accessed directory by name, e.g.

$lang = $Config{ZM_LANG_DEFAULT};

=head1 METHODS

=over 4

=item loadConfigFromDB ();

Loads existing configuration from the database (if any) and merges it with
the definitions held in this module. This results in the merging of any new
configuration and the removal of any deprecated configuration while
preserving the existing values of every else.

=item saveConfigToDB ();

Saves configuration held in memory to the database. The act of loading and
saving configuration is a convenient way to ensure that the configuration
held in the database corresponds with the most recent definitions and that
all components are using the same set of configuration.

=head2 EXPORT

None by default.
The :constants tag will export the ZM_PID constant which details the location of the zm.pid file
The :config tag will export all configuration from the database as well as any from the zm.conf file
The :all tag will export all above symbols.

=head1 SEE ALSO

http://www.zoneminder.com

=head1 AUTHOR

Philip Coombes, E<lt>philip.coombes@zoneminder.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2001-2008  Philip Coombes

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
