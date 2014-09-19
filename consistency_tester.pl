#!/usr/bin/perl -w
use strict;
use warnings;
use Redis;

print "Utility to consistency checking connection with Redis server\n";
if (@ARGV != 2) {
    die "Usage: $0 <hostname> <port>";
}

my $r = Redis->new(server => $ARGV[0].':'.$ARGV[1], reconnect => 1, every => 500 );
die "Can't connect to specified Redis: $ARGV[1]:$ARGV[2]" unless $r;

my $cc = ConsistencyTester->new({ redis => $r });

$cc->test();


# Basic consistency tester for checking Redis interaction
package ConsistencyTester;

# initialize object with Redis connection 
sub new {
    my ($class, $args) = @_;

    #initialize object
    my $self = {
            r               => $args->{redis},
            working_set     => 1000,
            keyspace        => 10000,
            writes          => 0,
            reads           => 0,
            failed_writes   => 0,
            failed_reads    => 0,
            lost_writes     => 0,
            not_ack_writes  => 0,
            delay           => 0,
            cached          => {},  # we take our view of data stored in the DB.
            prefix          => join('|', $$, time),
            errtime         => {},
        };

    bless $self, $class;
    return $self;
}

# generate key
sub genkey {
    my ($self) = @_;
    my $ks = rand() > 0.5 ? $self->{keyspace} : $self->{working_set};
    return $self->{prefix}."key_".int(rand($ks));
}

# check consistency 
sub check_consistency {
    my ($self, $key,  $value) = @_;
    my $expected = $self->{cached}->{$key};

    return unless $expected;

    if ($expected > $value) {
        $self->{lost_writes} += $expected - $value;
    } elsif ($expected < $value) {
        $self->{not_ack_writes} += $value - $expected;
    }
}

# save error
sub puterr {
    my ($self, $msg) = @_;
    if ( ! $self->{errtime}{$msg} || time != $self->{errtime}{$msg} ) {
        warn $msg;
    }
    $self->{errtime}->{$msg} = time();
}

# test procedure
sub test {
    my ($self) = @_;
    my $last_report = time();

    while (1) {
        my $key = $self->genkey();
        my $val;

        # Read
        eval {
            $val = $self->{r}->get($key);
            $self->check_consistency($key, $val);
            $self->{reads}++;
        };
        if ($@) {
            warn "Reading error: $@";
            $self->{failed_reads}++;
        } 

        # Write
        eval {
            $self->{cached}{$key} = $self->{r}->incr($key);
            $self->{writes}++;
        };
        if ($@) {
            warn "Writing error: $@";
            $self->{failed_writes}++;
        }

        # Report 
        sleep $self->{delay};

        if (time != $last_report) {
            my $report = "#".$self->{reads}. " R (#".$self->{failed_reads}." err)\n";
            $report .= "#".$self->{writes}." W (#".$self->{failed_writes}." err)\n";              
            $report .= "#".$self->{lost_writes}." lost |" if $self->{lost_writes} > 0;
            $report .= "#".$self->{not_ack_writes}." noack |" if $self->{not_ack_writes} > 0;

            $last_report = time;
            warn $report;
        }
    }
}

1;
