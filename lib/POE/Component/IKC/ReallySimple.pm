# $Header: /cvsroot/POE-Component-IKC-ReallySimple/lib/POE/Component/IKC/ReallySimple.pm,v 1.7 2001/09/28 22:32:04 matt Exp $

# DOCUMENTATION #{{{

=head1 NAME

POE::Component::IKC::ReallySimple - POE Component for simple inter-kernel communication

=head1 SYNOPSIS

    use POE qw(Component::IKC::ReallySimple);

    # in server
    poemsg_receive( ReceiveState => sub { print shift; } );
    $poe_kernel->run();

    # in client
    poemsg_send('HI');

=head1 DESCRIPTION

POE::Component::IKC::ReallySimple tries to make inter-kernel communication very
simple. POE::Component::IKC is great but it can be a lot of setup for
simple projects. This module hides the ick and complication of
inter-kernel messaging.

The synopsis really says it all.  C<poemsg_receive> sets a program up to
receive simple messages.  C<poemsg_send> sends a message. This is
UDP-like in that there is no real error checking to ensure the data goes
through. At this time, there is also no way to tell where your data came
from.

=head1 EXPORTED FUNCTIONS

=over 4

=cut

#}}}

package POE::Component::IKC::ReallySimple;
use warnings;
use strict;
use base qw(Exporter);
use Carp qw(carp croak);

use POE qw(
            Component::IKC::Server
            Component::IKC::ClientLite
          );

use vars qw ($VERSION @EXPORT);

@EXPORT = qw(poemsg_send poemsg_receive);
$VERSION = qw($Revision: 1.7 $)[1];

sub DEBUG () { 0 }

# sub poemsg_send #{{{

=head2 poemsg_send

    poemsg_send($data);
    poemsg_send($data,$server_ip);

Sends a message to a POE program. By default, it is assumed that the 
program is listening on 127.0.0.1. this assumption may be modified by 
passing a second parameter which is a dotted quad ip address.

Returns 1 if a successful server connection was made. Returns 0 if 
the server could not be contacted.

=cut


{ 
    my $conn;
    sub poemsg_send {
        my $msg = shift or croak "send() passed undef. needs something to send.";
        my $ip = shift || '127.0.0.1';
 
        unless($conn) {       
            print "Creating IKC Cilent\n" if DEBUG;
            $conn = create_ikc_client(
                            ip => $ip,
                            port => 31338,
                            subscribe => [ qw(poe://Msg/Msg/MsgInput) ],
                    );
        }
        if($conn) {
            $conn->post('poe://Msg/Msg/MsgInput',$msg);
            return 1;
        } else {
            return 0;
        }
    }
}
#}}}

# sub poemsg_receive #{{{

=head2 poemsg_receive
    
    poemsg_receive( ReceiveState => \&subroutine );
    poemsg_receive( ReceiveState => \&subroutine,
                        ServerIP => $server_ip,
                      ServerPort => $server_port
                  );

Listen and wait for incoming messages. C<&subroutine> will be passed 
the transmitted data when a message is received. The only guarantee 
about the incoming data is that it is a defined scalar. 

Parameters: C<ReceiveState> takes a code reference which will receive
passed data as indicated above. This parameter is not optional.  
C<ServerIP> sets the ip address to which the server binds. This 
parameter is optional and defaults to C<127.0.0.1>. C<ServerPort> set 
the socket port to which the server binds. This parameter is optional 
and binds C<31338>.
 
C<$poe_kernel-E<gt>run()> must still be done in the server. sometime 
soon, this will be a little bit easier. 

=cut

sub poemsg_receive {
    my %args = @_;
    my $coderef = $args{ReceiveState};
    my $ip = $args{ServerIP} || '127.0.0.1';
    my $port = $args{ServerPort} || 31338;
    
    unless($coderef && ref $coderef eq 'CODE') {
        croak "receive() was passed bad arguments. its only argument must be a subroutine reference."
    }
    print "Starting ikc server...\n" if DEBUG;
    create_ikc_server(
        ip => $ip,
        port => $port,
        name => 'Msg',
    );
    
    print "Starting control session...\n" if DEBUG;
    POE::Session->create(
        inline_states => {
            _start => \&session_start,
            _stop => \&session_stop,

            MsgInput => \&msg_input,
        },
        args => [ $coderef ],
    );
    print "Returning...\n" if DEBUG;
    return 1;
}
#}}}

# sub session_start #{{{

=begin internals

=head2 session_start

set up ikc stuff. sit and wait for data. used by poemsg_receive.

=cut

sub session_start {
    my ($kernel,$heap, $coderef) = @_[KERNEL,HEAP,ARG0];
    print "Control Session start\n" if DEBUG; 
    $heap->{coderef} = $coderef;
    
    $kernel->alias_set('Msg');
    $kernel->call('IKC','publish','Msg', [ qw(MsgInput) ]);
}
#}}}

# sub session_stop #{{{

=head2 session_stop

called on session stoppage. no-op.

=cut

sub session_stop {
    # should probably notify someone, eh?
    print "Control Session stop\n" if DEBUG;
}
#}}}

# sub msg_input #{{{

=head2 msg_input

wrapper for ikc input. simply passes the incoming data to the 
supplied coderef.

=cut

sub msg_input {
    print "msg_input\n" if DEBUG;
    $_[HEAP]->{coderef}->($_[ARG0]);
}
#}}}

1; 

=end internals

=back

=head1 AUTHOR

	Matt Cashner
	CPAN ID: MCASHNER
	eek+cpan@eekeek.org
	http://eekeek.org/perl/

=head1 COPYRIGHT

Copyright (c) 2001 Matt Cashner. All rights reserved.
This program is free software licensed under the...

	The MIT License

The full text of the license can be found in the
LICENSE file included with this module.

=cut
