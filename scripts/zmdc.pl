#!/usr/bin/perl -wT
#
# ==========================================================================
#
# ZoneMinder Daemon Control Script, $Date$, $Revision$
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

zmdc.pl - ZoneMinder Daemon Control script

=head1 SYNOPSIS

 zmdc.pl {command} [daemon [options]]

=head1 DESCRIPTION

This script is the gateway for controlling the various ZoneMinder
daemons. All starting, stopping and restarting goes through here.
On the first invocation it starts up a server which subsequently
records what's running and what's not. Other invocations just
connect to the server and pass instructions to it.

=head1 OPTIONS

 {command}           - One of 'startup|shutdown|status|check|logrot' or
                       'start|stop|restart|reload|version'.
 [daemon [options]]  - Daemon name and options, required for second group of commands

=cut
use strict;
use bytes;

# ==========================================================================
#
# User config
#
# ==========================================================================

use constant MAX_CONNECT_DELAY => 10;

# ==========================================================================
#
# Don't change anything from here on down
#
# ==========================================================================

# Include from system perl paths only
use ZoneMinder;
use POSIX;
use Socket;
use IO::Handle;
use autouse 'Pod::Usage'=>qw(pod2usage);
#use Data::Dumper;

use constant SOCK_FILE => $Config{ZM_PATH_SOCKS}.'/zmdc'.($Config{ZM_SERVER_ID}?$Config{ZM_SERVER_ID}:'').'.sock';

$| = 1;

$ENV{PATH}  = '/bin:/usr/bin:/usr/local/bin';
$ENV{SHELL} = '/bin/sh' if exists $ENV{SHELL};
if ( $Config{ZM_LD_PRELOAD} ) {
  Debug("Adding ENV{LD_PRELOAD} = $Config{ZM_LD_PRELOAD}");
  $ENV{LD_PRELOAD} = $Config{ZM_LD_PRELOAD};
  foreach my $lib ( split(/\s+/, $ENV{LD_PRELOAD} ) ) {
    if ( ! -e $lib ) {
      Warning("LD_PRELOAD lib $lib does not exist from LD_PRELOAD $ENV{LD_PRELOAD}.");
    }
  }
}
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

my @daemons = (
    'zmc',
    'zma',
    'zmfilter.pl',
    'zmaudit.pl',
    'zmtrigger.pl',
    'zmx10.pl',
    'zmwatch.pl',
    'zmupdate.pl',
    'zmtrack.pl',
    'zmtelemetry.pl'
);

my $command = shift @ARGV;
if( !$command )
{
    print( STDERR "No command given\n" );
    pod2usage(-exitstatus => -1);
}
if ( $command eq 'version' ) {
    print ZoneMinder::Base::ZM_VERSION."\n";
    exit( 0 );
}
my $needs_daemon = $command !~ /(?:startup|shutdown|status|check|logrot|version)/;
my $daemon = shift( @ARGV );
if( $needs_daemon && !$daemon )
{
    print( STDERR "No daemon given\n" );
    pod2usage(-exitstatus => -1);
}
my @args;

my $daemon_patt = '('.join( '|', @daemons ).')';
if ( $needs_daemon )
{
    if ( $daemon =~ /^${daemon_patt}$/ )
    {
        $daemon = $1;
    }
    else
    {
        print( STDERR "Invalid daemon '$daemon' specified" );
        pod2usage(-exitstatus => -1);
    }
}

foreach my $arg ( @ARGV )
{
    # Detaint arguments, if they look ok
    #if ( $arg =~ /^(-{0,2}[\w]+)/ )
    if ( $arg =~ /^(-{0,2}[\w\/?&=.-]+)$/ )
    {
        push( @args, $1 );
    }
    else
    {
        print( STDERR "Bogus argument '$arg' found" );
        exit( -1 );
    }
}

socket( CLIENT, PF_UNIX, SOCK_STREAM, 0 ) or Fatal( "Can't open socket: $!" );

my $saddr = sockaddr_un( SOCK_FILE );
my $server_up = connect( CLIENT, $saddr );
if ( !$server_up )
{
    if ( $command eq "logrot" )
    {
        exit();
    }
    if ( $command eq "check" )
    {
        print( "stopped\n" );
        exit();
    }
    elsif ( $command ne "startup" )
    {
        print( "Unable to connect to server\n" );
        exit( -1 );
    }
    # The server isn't there
    print( "Starting server\n" );
    close( CLIENT );

    if ( my $cpid = fork() )
    {
        logInit();

        # Parent process just sleep and fall through
        socket( CLIENT, PF_UNIX, SOCK_STREAM, 0 ) or Fatal( "Can't open socket: $!" );
        my $attempts = 0;
        while (!connect( CLIENT, $saddr ))
        {
            $attempts++;
            Fatal( "Can't connect: $!" ) if ($attempts > MAX_CONNECT_DELAY);
            sleep(1);
        }
    }
    elsif ( defined($cpid) )
    {
        ZMServer::run();
    }
    else
    {
        Fatal( "Can't fork: $!" );
    }
}
if ( $command eq "check" && !$daemon )
{
    print( "running\n" );
    exit();
}
elsif ( $command eq "startup" )
{
    # Our work here is done
    exit() if ( !$server_up );
}
# The server is there, connect to it
#print( "Writing commands\n" );
CLIENT->autoflush();
my $message = "$command";
$message .= ";$daemon" if ( $daemon );
$message .= ";".join( ';', @args ) if ( @args );
print( CLIENT $message );
shutdown( CLIENT, 1 );
while ( my $line = <CLIENT> )
{
    chomp( $line );
    print( "$line\n" );
}
# And we're done!
close( CLIENT );
#print( "Finished writing, bye\n" );

exit;

package ZMServer;

use strict;
use bytes;

# Include from system perl paths only
use ZoneMinder;
use POSIX;
use Socket;
use IO::Handle;
#use Data::Dumper;

our %cmd_hash;
our %pid_hash;

sub run
{
    my $fd = 0;
    while( $fd < POSIX::sysconf( &POSIX::_SC_OPEN_MAX ) )
    {
        POSIX::close( $fd++ );
    }

    setpgrp();

    logInit();

    dPrint( ZoneMinder::Logger::INFO, "Server starting at "
        .strftime( '%y/%m/%d %H:%M:%S', localtime() )
        ."\n"
    );

    if ( open( my $PID, '>', ZM_PID ) )
    {
        print( $PID $$ );
        close( $PID );
	} else {
		Error( "Can't open pid file at " . ZM_PID );
    }

    killAll( 1 );

    socket( SERVER, PF_UNIX, SOCK_STREAM, 0 ) or Fatal( "Can't open socket: $!" );
    unlink( main::SOCK_FILE ) or Error( "Unable to unlink " . main::SOCK_FILE .". Error message was: $!" ) if ( -e main::SOCK_FILE );
    bind( SERVER, $saddr ) or Fatal( "Can't bind to " . main::SOCK_FILE . ": $!" );
    listen( SERVER, SOMAXCONN ) or Fatal( "Can't listen: $!" );

    $SIG{CHLD} = \&reaper;
    $SIG{INT} = \&shutdownAll;
    $SIG{TERM} = \&shutdownAll;
    $SIG{ABRT} = \&shutdownAll;
    $SIG{HUP} = \&logrot;

    my $rin = '';
    vec( $rin, fileno(SERVER), 1 ) = 1;
    my $win = $rin;
    my $ein = $win;
    my $timeout = 0.1;
    while( 1 )
    {
        my $nfound = select( my $rout = $rin, undef, undef, $timeout );
        if ( $nfound > 0 )
        {
            if ( vec( $rout, fileno(SERVER), 1 ) )
            {
                my $paddr = accept( CLIENT, SERVER );
                my $message = <CLIENT>;

                next if ( !$message );

                my ( $command, $daemon, @args ) = split( /;/, $message );

                if ( $command eq 'start' )
                {
                    start( $daemon, @args );
                }
                elsif ( $command eq 'stop' )
                {
                    stop( $daemon, @args );
                }
                elsif ( $command eq 'restart' )
                {
                    restart( $daemon, @args );
                }
                elsif ( $command eq 'reload' )
                {
                    reload( $daemon, @args );
                }
                elsif ( $command eq 'startup' )
                {
                    # Do nothing, this is all we're here for
                    dPrint( ZoneMinder::Logger::WARNING, "Already running, ignoring command '$command'\n" );
                }
                elsif ( $command eq 'shutdown' )
                {
                    shutdownAll();
                }
                elsif ( $command eq 'check' )
                {
                    check( $daemon, @args );
                }
                elsif ( $command eq 'status' )
                {
                    if ( $daemon )
                    {
                        status( $daemon, @args );
                    }
                    else
                    {
                        status();
                    }
                }
                elsif ( $command eq 'logrot' )
                {
                    logrot();
                }
                else
                {
                    dPrint( ZoneMinder::Logger::ERROR, "Invalid command '$command'\n" );
                }
                close( CLIENT );
            }
            else
            {
                Fatal( "Bogus descriptor" );
            }
        }
        elsif ( $nfound < 0 )
        {
            if ( $! == EINTR )
            {
                # Dead child, will be reaped
                #print( "Probable dead child\n" );
                # See if it needs to start up again
                restartPending();
            }
            elsif ( $! == EPIPE )
            {
                Error( "Can't select: $!" );
            }
            else
            {
                Fatal( "Can't select: $!" );
            }
        }
        else
        {
            #print( "Select timed out\n" );
            restartPending();
        }
    }
    dPrint( ZoneMinder::Logger::INFO, "Server exiting at "
        .strftime( '%y/%m/%d %H:%M:%S', localtime() )
        ."\n"
    );
    unlink( main::SOCK_FILE ) or Error( "Unable to unlink " . main::SOCK_FILE .". Error message was: $!" ) if ( -e main::SOCK_FILE );
    unlink( ZM_PID ) or Error( "Unable to unlink " . ZM_PID .". Error message was: $!" ) if ( -e ZM_PID );
    exit();
}

sub cPrint
{
    if ( fileno(CLIENT) )
    {
        print CLIENT @_
    }
}

sub dPrint
{
    my $logLevel = shift;
    if ( fileno(CLIENT) )
    {
        print CLIENT @_
    }
    if ( $logLevel == ZoneMinder::Logger::DEBUG )
    {
        Debug( @_ );
    }
    elsif ( $logLevel == ZoneMinder::Logger::INFO )
    {
        Info( @_ );
    }
    elsif ( $logLevel == ZoneMinder::Logger::WARNING )
    {
        Warning( @_ );
    }
    elsif ( $logLevel == ZoneMinder::Logger::ERROR )
    {
        Error( @_ );
    }
    elsif ( $logLevel == ZoneMinder::Logger::FATAL )
    {
        Fatal( @_ );
    }
}

sub start
{
    my $daemon = shift;
    my @args = @_;

    my $command = join(' ', $daemon, @args );
    my $process = $cmd_hash{$command};

    if ( !$process )
    {
        # It's not running, or at least it's not been started by us
        $process = { daemon=>$daemon, args=>\@args, command=>$command, keepalive=>!undef };
    }
    elsif ( $process->{pid} && $pid_hash{$process->{pid}} )
    {
        dPrint( ZoneMinder::Logger::INFO, "'$process->{command}' already running at "
            .strftime( '%y/%m/%d %H:%M:%S', localtime( $process->{started}) )
            .", pid = $process->{pid}\n"
        );
        return();
    }

    my $sigset = POSIX::SigSet->new;
    my $blockset = POSIX::SigSet->new( SIGCHLD );
    sigprocmask( SIG_BLOCK, $blockset, $sigset ) or Fatal( "Can't block SIGCHLD: $!" );
    if ( my $cpid = fork() )
    {
        logReinit();

        $process->{pid} = $cpid;
        $process->{started} = time();
        delete( $process->{pending} );

        dPrint( ZoneMinder::Logger::INFO, "'$command' starting at "
            .strftime( '%y/%m/%d %H:%M:%S', localtime( $process->{started}) )
            .", pid = $process->{pid}\n"
        );

        $cmd_hash{$process->{command}} = $pid_hash{$cpid} = $process;
        sigprocmask( SIG_SETMASK, $sigset ) or Fatal( "Can't restore SIGCHLD: $!" );
    }
    elsif ( defined($cpid ) )
    {
        logReinit();

        dPrint( ZoneMinder::Logger::INFO, "'".join( ' ', ( $daemon, @args ) )
            ."' started at "
            .strftime( '%y/%m/%d %H:%M:%S', localtime() )
            ."\n"
        );

        if ( $daemon =~ /^${daemon_patt}$/ )
        {
            $daemon = $Config{ZM_PATH_BIN}.'/'.$1;
        }
        else
        {
            Fatal( "Invalid daemon '$daemon' specified" );
        }

        my @good_args;
        foreach my $arg ( @args )
        {
            # Detaint arguments, if they look ok
            if ( $arg =~ /^(-{0,2}[\w\/?&=.-]+)$/ )
            {
                push( @good_args, $1 );
            }
            else
            {
                Fatal( "Bogus argument '$arg' found" );
            }
        }

        logTerm();

        my $fd = 0;
        while( $fd < POSIX::sysconf( &POSIX::_SC_OPEN_MAX ) )
        {
            POSIX::close( $fd++ );
        }

        # Child process
        $SIG{CHLD} = 'DEFAULT';
        $SIG{INT} = 'DEFAULT';
        $SIG{TERM} = 'DEFAULT';
        $SIG{ABRT} = 'DEFAULT';

        exec( $daemon, @good_args ) or Fatal( "Can't exec: $!" );
    }
    else
    {
        Fatal( "Can't fork: $!" );
    }
}

# Sends the stop signal, without waiting around to see if the process died.
sub send_stop {
    my ( $final, $process ) = @_;

    my $command = $process->{command};
    if ( $process->{pending} ) {

        delete( $cmd_hash{$command} );
        dPrint( ZoneMinder::Logger::INFO, "Command '$command' removed from pending list at "
            .strftime( '%y/%m/%d %H:%M:%S', localtime() )
            ."\n"
        );
        return();
    }

    my $pid = $process->{pid};
    if ( !$pid_hash{$pid} )
    {
        dPrint( ZoneMinder::Logger::ERROR, "No process with command of '$command' pid $pid is running\n" );
        return();
    }

    dPrint( ZoneMinder::Logger::INFO, "'$command' sending stop to pid $pid at "
        .strftime( '%y/%m/%d %H:%M:%S', localtime() )
        ."\n"
    );
    $process->{keepalive} = !$final;
    kill( 'TERM', $pid );
    return $pid;
} # end sub send_stop

sub kill_until_dead {
    my ( $process ) = @_;
    # Now check it has actually gone away, if not kill -9 it
    my $count = 0;
    while( $process and $$process{pid} and kill( 0, $$process{pid} ) )
    {
        if ( $count++ > 5 )
        {
            dPrint( ZoneMinder::Logger::WARNING, "'$$process{command}' has not stopped at "
                .strftime( '%y/%m/%d %H:%M:%S', localtime() )
                .". Sending KILL to pid $$process{pid}\n"
            );
            kill( 'KILL', $$process{pid} );
        }
        
        sleep( 1 );
    }
}

sub _stop {
    my ($final, $process ) = @_;

    my $pid = send_stop( $final, $process );
    return if ! $pid;
    delete( $cmd_hash{$$process{command}} );

    kill_until_dead( $process );
}

sub stop
{
    my ( $daemon, @args ) = @_;
    my $command = join(' ', $daemon, @args );
    my $process = $cmd_hash{$command};
    if ( !$process )
    {
        dPrint( ZoneMinder::Logger::WARNING, "Can't find process with command of '$command'\n" );
        return();
    }

    _stop( 1, $process );
}

sub restart
{
    my $daemon = shift;
    my @args = @_;

    my $command = $daemon;
    $command .= ' '.join( ' ', ( @args ) ) if ( @args );
    my $process = $cmd_hash{$command};
    if ( $process )
    {
        if ( $process->{pid} )
        {
            my $cpid = $process->{pid};
            if ( defined($pid_hash{$cpid}) )
            {
                _stop( 0, $process );
                return;
            }
        }
    }
    start( $daemon, @args );
}

sub reload
{
    my $daemon = shift;
    my @args = @_;

    my $command = $daemon;
    $command .= ' '.join( ' ', ( @args ) ) if ( @args );
    my $process = $cmd_hash{$command};
    if ( $process )
    {
        if ( $process->{pid} )
        {
            kill( 'HUP', $process->{pid} );
        }
    }
}

sub logrot
{
    logReinit();
    foreach my $process ( values( %pid_hash ) )
    {
        if ( $process->{pid} && $process->{command} =~ /^zm.*\.pl/ )
        {
            kill( 'HUP', $process->{pid} );
        }
    }
}

sub reaper
{
    my $saved_status = $!;
    while ( (my $cpid = waitpid( -1, WNOHANG )) > 0 )
    {
        my $status = $?;

        my $process = $pid_hash{$cpid};
        delete( $pid_hash{$cpid} );

        if ( !$process )
        {
            dPrint( ZoneMinder::Logger::INFO, "Can't find child with pid of '$cpid'\n" );
            next;
        }

        $process->{stopped} = time();
        $process->{runtime} = ($process->{stopped}-$process->{started});
        delete( $process->{pid} );

        my $exit_status = $status>>8;
        my $exit_signal = $status&0xfe;
        my $core_dumped = $status&0x01;

        my $out_str = "'$process->{command}' ";
        if ( $exit_signal )
        {
            if ( $exit_signal == 15 || $exit_signal == 14 ) # TERM or ALRM
            {
                $out_str .= "exited";
            }
            else
            {
                $out_str .= "crashed";
            }
            $out_str .= ", signal $exit_signal";
        }
        else
        {
            $out_str .= "exited ";
            if ( $exit_status )
            {
                $out_str .= "abnormally, exit status $exit_status";
            }
            else
            {
                $out_str .= "normally";
            }
        }
        #print( ", core dumped" ) if ( $core_dumped );
        $out_str .= "\n";

        if ( $exit_status == 0 )
        {
            Info( $out_str );
        }
        else
        {
            Error( $out_str );
        }

        if ( $process->{keepalive} )
        {
            # Schedule for immediate restart
            $cmd_hash{$process->{command}} = $process;
            if ( !$process->{delay} || ($process->{runtime} > $Config{ZM_MAX_RESTART_DELAY} ) )
            {
                #start( $process->{daemon}, @{$process->{args}} );
                $process->{pending} = $process->{stopped};
                $process->{delay} = 5;
            }
            else
            {
                $process->{pending} = $process->{stopped}+$process->{delay};
                $process->{delay} *= 2;
                # Limit the start delay to 15 minutes max
                if ( $process->{delay} > $Config{ZM_MAX_RESTART_DELAY} )
                {
                    $process->{delay} = $Config{ZM_MAX_RESTART_DELAY};
                }
            }
        }
    }
    $SIG{CHLD} = \&reaper;
    $! = $saved_status;
}

sub restartPending
{
    # Restart any pending processes
    foreach my $process ( values( %cmd_hash ) )
    {
        if ( $process->{pending} && $process->{pending} <= time() )
        {
            dPrint( ZoneMinder::Logger::INFO, "Starting pending process, $process->{command}\n" );
            start( $process->{daemon}, @{$process->{args}} );
        }
    }
}

sub shutdownAll
{
    foreach my $pid ( keys %pid_hash ) {
        # This is a quick fix because a SIGCHLD can happen and alter pid_hash while we are in here.
        next if ! $pid_hash{$pid};
        send_stop( 1, $pid_hash{$pid} );
    }
    foreach my $pid ( keys %pid_hash ) {
        # This is a quick fix because a SIGCHLD can happen and alter pid_hash while we are in here.
        next if ! $pid_hash{$pid};

        my $process = $pid_hash{$pid};

        kill_until_dead( $process );
        delete( $cmd_hash{$$process{command}} );
        delete( $pid_hash{$pid} );
    }
    killAll( 5 );
    dPrint( ZoneMinder::Logger::INFO, "Server shutdown at "
        .strftime( '%y/%m/%d %H:%M:%S', localtime() )
        ."\n"
    );
    unlink( main::SOCK_FILE ) or Error( "Unable to unlink " . main::SOCK_FILE .". Error message was: $!" ) if ( -e main::SOCK_FILE );
    unlink( ZM_PID ) or Error( "Unable to unlink " . ZM_PID .". Error message was: $!" ) if ( -e ZM_PID );
    close( CLIENT );
    close( SERVER );
    exit();
}

sub check
{
    my $daemon = shift;
    my @args = @_;

    my $command = $daemon;
    $command .= ' '.join( ' ', ( @args ) ) if ( @args );
    my $process = $cmd_hash{$command};
    if ( !$process )
    {
        cPrint( "unknown\n" );
    }
    elsif ( $process->{pending} )
    {
        cPrint( "pending\n" );
    }
    else
    {
        my $cpid = $process->{pid};
        if ( !$pid_hash{$cpid} )
        {
            cPrint( "stopped\n" );
        }
        else
        {
            cPrint( "running\n" );
        }
    }
}

sub status
{
    my $daemon = shift;
    my @args = @_;

    if ( defined($daemon) )
    {
        my $command = $daemon;
        $command .= ' '.join( ' ', ( @args ) ) if ( @args );
        my $process = $cmd_hash{$command};
        if ( !$process )
        {
            dPrint( ZoneMinder::Logger::DEBUG, "'$command' not running\n" );
            return();
        }

        if ( $process->{pending} )
        {
            dPrint( ZoneMinder::Logger::DEBUG, "'$process->{command}' pending at "
                .strftime( '%y/%m/%d %H:%M:%S', localtime( $process->{pending}) )
                ."\n"
            );
        }
        else
        {
            my $cpid = $process->{pid};
            if ( !$pid_hash{$cpid} )
            {
                dPrint( ZoneMinder::Logger::DEBUG, "'$command' not running\n" );
                return();
            }
        }
        dPrint( ZoneMinder::Logger::DEBUG, "'$process->{command}' running since "
            .strftime( '%y/%m/%d %H:%M:%S', localtime( $process->{started}) )
            .", pid = $process->{pid}"
        );
    }
    else
    {
        foreach my $process ( values(%pid_hash) )
        {
            my $out_str = "'$process->{command}' running since "
                .strftime( '%y/%m/%d %H:%M:%S', localtime( $process->{started}) )
                .", pid = $process->{pid}"
            ;
            $out_str .= ", valid" if ( kill( 0, $process->{pid} ) );
            $out_str .= "\n";
            dPrint( ZoneMinder::Logger::DEBUG, $out_str );
        }
        foreach my $process ( values( %cmd_hash ) )
        {
            if ( $process->{pending} )
            {
                dPrint( ZoneMinder::Logger::DEBUG, "'$process->{command}' pending at "
                    .strftime( '%y/%m/%d %H:%M:%S', localtime( $process->{pending}) )
                    ."\n"
                );
            }
        }
    }
}

sub killAll
{
    my $delay = shift;
    sleep( $delay );
    my $killall;
    if ( 'linux' eq 'BSD' )
    {
        $killall = 'killall -q -';
    } elsif ( 'linux' eq 'solaris' ) {
        $killall = 'pkill -';
    } else {
        $killall = 'killall -q -s ';
    }
    foreach my $daemon ( @daemons )
    {
        my $cmd = $killall ."TERM $daemon";
        Debug( $cmd );
        qx( $cmd );
    }
    sleep( $delay );
    foreach my $daemon ( @daemons )
    {
        my $cmd = $killall."KILL $daemon";
        Debug( $cmd );
        qx( $cmd );
    }
}
