#!/usr/bin/perl -w
use strict;
use lib 'lib';
use Redis::Cluster;
use Data::Dumper;

my $cluster_type = 'ProxySharding'; # NativeSharding | ClientSharding

print "Test stand for Redis cluster ($cluster_type)\n";

# twemProxy nodes


my $nodes = ['172.19.10.113:4000', '172.19.10.116:4000'];

# Specify twemproxy as a cluster entrypoint
my $cluster = Redis::Cluster->new(
				type => $cluster_type,  	
 				# Connect to random node (as a first temporal solution)
				nodes => $nodes,
				# Connection settings 
				cnx_timeout => 1,	# connection timeout 
				read_timeout => 0.5,	# read commands timeout
				write_timeout => 0.5,	# write commands timeout
				# reconnection options
				reconnect => 3,   #sec
				every => 500,     #try reconnect every 500 msec
				encoding => undef,
				debug => 0,
				no_auto_connect_on_new => 1,
	#			name => 'cluster_connection',	
);

# Create connection to th cluster
$cluster->connect();

print Dumper($cluster);

#perform commands to the cluster
my $val =  $cluster->get("test");

print "V=$val\n";


