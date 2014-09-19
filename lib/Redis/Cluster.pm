package Redis::Cluster;
use strict;
use Redis;
#use base qw(Redis);

use Redis::Cluster::ProxySharding;
=item DESCRIPTION 
	Base class for Redis cluster client

=cut


=item new
	Constructor
		return new connector object to Redis cluster
=cut
sub new {
	my ($class, %args ) = @_;

	my $type = $args{type} || 'ProxySharding';

	# dispatch over implementation subclasses
	my $subclass = 'Redis::Cluster::'.$type;
	return $subclass->create(%args);

	#return $class->SUPER::new(%args);
}


sub connect {


}


=item _is_valid_cmd

=cut
#sub _is_valid_cmd {
#
#}


1;
