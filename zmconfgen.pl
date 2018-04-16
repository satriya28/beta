#!/usr/bin/perl -w
#
# ==========================================================================
#
# Zone Minder Configuration Script, $Date$, $Revision$
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
# This script is used to generate initial config headers and database data.
#

use strict;
use lib './scripts/ZoneMinder/lib';
use ZoneMinder::ConfigData qw/:data/;

$| = 1;

my $config_header = "src/zm_config_defines.h";
my $config_sql = "db/zm_create.sql";

generateConfigFiles();

exit;

sub generateConfigFiles
{
	generateConfigHeader();
	generateConfigSQL();
}

sub generateConfigHeader
{
	print( "Generating '$config_header'\n" );
	open( CFG_HDR_FILE, ">$config_header" ) or die( "Can't open '$config_header' for writing" );
	print( CFG_HDR_FILE "// The file is autogenerated by zmconfgen.pl\n" );
	print( CFG_HDR_FILE "// Do not edit this file as any changes will be overwritten\n\n" );
	my $last_id = 0;
	my $define_list = "";
	my $declare_list = "";
	my $assign_list = "";
	foreach my $option ( @options )
	{
		next if ( !defined($option->{id}) );

		my $opt_id = $option->{id};
		my $opt_name = $option->{name};
		my $opt_type = $option->{type};
		my $var_name = substr( lc($opt_name), 3 );

		$define_list .= sprintf( "#define $opt_name $opt_id\n" );

		$declare_list .= sprintf( "\t" );
		if ( $opt_type->{db_type} eq 'boolean' )
		{
			$declare_list .= sprintf( "bool " );
		}
		elsif ( $opt_type->{db_type} eq 'integer' || $opt_type->{db_type} eq 'hexadecimal' )
		{
			$declare_list .= sprintf( "int " );
		}
		elsif ( $opt_type->{db_type} eq 'decimal' )
		{
			$declare_list .= sprintf( "double " );
		}
		else
		{
			$declare_list .= sprintf( "const char *" );
		}
		$declare_list .= sprintf( $var_name.";\\\n" );

		$assign_list .= sprintf( "\t" );
		$assign_list .= sprintf( $var_name." = " );
		if ( $opt_type->{db_type} eq 'boolean' )
		{
			$assign_list .= sprintf( "(bool)" );
		}
		elsif ( $opt_type->{db_type} eq 'integer' || $opt_type->{db_type} eq 'hexadecimal' )
		{
			$assign_list .= sprintf( "(int)" );
		}
		elsif ( $opt_type->{db_type} eq 'decimal' )
		{
			$assign_list .= sprintf( "(double) " );
		}
		else
		{
			$assign_list .= sprintf( "(const char *)" );
		}
		$assign_list .= sprintf( "config.Item( ".$opt_name." );\\\n" );

		$last_id = $option->{id};
	}
	print( CFG_HDR_FILE $define_list."\n\n" );
	print( CFG_HDR_FILE "#define ZM_MAX_CFG_ID $last_id\n\n" );
	print( CFG_HDR_FILE "#define ZM_CFG_DECLARE_LIST \\\n" );
	print( CFG_HDR_FILE $declare_list."\n\n" );
	print( CFG_HDR_FILE "#define ZM_CFG_ASSIGN_LIST \\\n" );
	print( CFG_HDR_FILE $assign_list."\n\n" );
	close( CFG_HDR_FILE );
}

sub generateConfigSQL
{
	print( "Updating '$config_sql'\n" );
	my $config_sql_temp = $config_sql.".temp";
	open( CFG_SQL_FILE, "<$config_sql" ) or die( "Can't open '$config_sql' for reading" );
	open( CFG_TEMP_SQL_FILE, ">$config_sql_temp" ) or die( "Can't open '$config_sql_temp' for writing" );
	while ( my $line = <CFG_SQL_FILE> )
	{
		last if ( $line =~ /^-- This section is autogenerated/ );
		print( CFG_TEMP_SQL_FILE $line );
	}
	close( CFG_SQL_FILE );

	print( CFG_TEMP_SQL_FILE "-- This section is autogenerated by zmconfgen.pl\n" );
	print( CFG_TEMP_SQL_FILE "-- Do not edit this file as any changes will be overwritten\n" );
	print( CFG_TEMP_SQL_FILE "--\n\n" );
	print( CFG_TEMP_SQL_FILE "delete from Config;\n\n" );
	foreach my $option ( @options )
	{
		#print( $option->{name}."\n" ) if ( !$option->{category} );
		$option->{db_type} = $option->{type}->{db_type};
		$option->{db_hint} = $option->{type}->{hint};
		$option->{db_pattern} = $option->{type}->{pattern};
		$option->{db_format} = $option->{type}->{format};
		if ( $option->{db_type} eq "boolean" )
		{
			$option->{db_value} = ($option->{value} eq "yes")?"1":"0";
		}
		else
		{
			$option->{db_value} = $option->{value};
		}
        if ( $option->{name} eq "ZM_DYN_CURR_VERSION" || $option->{name} eq "ZM_DYN_DB_VERSION" )
        {
            $option->{db_value} = '1.30.4';
        }
		if ( my $requires = $option->{requires} )
		{
			$option->{db_requires} = join( ";", map { my $value = $_->{value}; $value = ($value eq "yes")?1:0 if ( $options_hash{$_->{name}}->{db_type} eq "boolean" ); ( "$_->{name}=$value" ) } @$requires );
		}
		else
		{
			$option->{db_requires} = "";
		}
		printf( CFG_TEMP_SQL_FILE
			"insert into Config set Id = %d, Name = '%s', Value = '%s', Type = '%s', DefaultValue = '%s', Hint = '%s', Pattern = '%s', Format = '%s', Prompt = '%s', Help = '%s', Category = '%s', Readonly = '%s', Requires = '%s';\n",
			$option->{id},
			$option->{name},
			addSlashes($option->{db_value}),
			$option->{db_type},
			addSlashes($option->{default}),
			addSlashes($option->{db_hint}),
			addSlashes($option->{db_pattern}),
			addSlashes($option->{db_format}),
			addSlashes($option->{description}),
			addSlashes($option->{help}),
			$option->{category},
			$option->{readonly}?1:0,
			$option->{db_requires}
		);
	}
	print( CFG_TEMP_SQL_FILE "\n" );
	close( CFG_TEMP_SQL_FILE );

	rename( $config_sql_temp, $config_sql ) or die( "Can't rename '$config_sql_temp' to '$config_sql': $!" );
}

sub addSlashes
{
	my $string = shift;
    return( "" ) if ( !defined($string) );
	$string =~ s|(['"])|\\$1|g;
	return( $string );
}
