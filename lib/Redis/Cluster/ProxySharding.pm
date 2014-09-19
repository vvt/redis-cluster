package Redis::Cluster::ProxySharding;
use strict;
use base qw(Redis::Cluster);
use Redis;

=item INTRO
	Redis cluster based on Redis sharding proxy (twemproxy)
	Main features of Proxy Cluster:
	1. Open some connections to proxy nodes (couple connections) - 
	2. Restricts some commands (which are not permitted by twemproxy)
        3. Add some utility functions:
            - Keys tagging
            - get key node
            - get direct connection to the node
	    - free space estimation

=cut

=item new
	Constructor
=cut
sub new {

}

=item create
	Constructor implementation
=cut
sub create {
	my ($class, %args) = @_;

	
	my $self = {
		nodes 	=> $args{nodes},
		server 	=> $args{nodes}->[rand(scalar(@{$args{nodes}}))],

	};

	my %redis_options = ();

	foreach my $opt_name (	grep { exists $args{$_} } qw(cnx_timeout read_timeout write_timeout reconnect every encoding debug no_auto_connect_on_new)) {
		$self->{$opt_name} = $args{$opt_name};
		$redis_options{$opt_name} = $args{$opt_name};
	}

	$self->{r} = Redis->new(server => $self->{server}, %redis_options);

	bless $self, $class;
	return $self;
}

=item connect
	Connect
=cut
sub connect {
	my ($self) = @_;
	$self->{r}->connect();
}


=item _check_cmd

=cut
sub _check_cmd {

}


1;
