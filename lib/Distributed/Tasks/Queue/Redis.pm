package Distributed::Tasks::Queue::Redis;
use Moose;
use JSON::XS;

has queue_name => ( is => 'rw', default => sub { "my_jobs" }  );
has hash_name  => ( is => 'rw', default => sub { "my_hash" }  );
has [ qw/client expiration_time/]     => ( is => 'rw' );

sub insert_on_end {
    my ( $self, $args ) = @_;
    my $count_items = $self->client->rpush(
        $self->queue_name
        , encode_json( $args )
    );
#   $self->client->setex( $args->{ id }, $self->expiration_time, "job id saved for some seconds and will expire" );
    $self->client->hset( $self->hash_name, $args->{ id } => "job id saved for some seconds and will expire" );
}

sub insert_on_begining {
    my ( $self, $args ) = @_;
    my $count_items = $self->client->lpush( 
        $self->queue_name ,
        encode_json( $args )
    );
#   $self->client->setex( $args->{ id }, $self->expiration_time, "job id saved for some seconds and will expire" );
    $self->client->hset( $self->hash_name, $args->{ id } => "job id saved for some seconds and will expire" );
}

sub append {
  my ( $self, $args ) = @_;
  if ( !$self->client->hget( $self->hash_name, $args->{ id } ) ) {
      $self->insert_on_end( $args );
      return 1;
  }
  return 0;
}

sub prepend {
    my ( $self, $args ) = @_; #args = { id => $id, job => $job, expire_date => '...' }
    if ( !$self->client->hget( $self->hash_name, $args->{ id } ) ) {
        $self->insert_on_begining( $args );
        return 1;
    }
    return 0;
}



sub _analyse_job {
    my ( $self, $job ) = @_; 
    if ( defined $job ) {
      my $job = decode_json ( $job );
      if ( exists $job->{ id } ) {
        $self->client->hdel( $self->hash_name, $job->{ id } );
        return $job;
      }
    }
    return 0;
}

=head2 get

process one item from the queue

=cut

sub get {
    my ( $self ) = @_;
    my $job = $self->client->lpop( $self->queue_name );
    return $self->_analyse_job( $job );
}

=head2 get_job_blocking 

process jobs inside a loop, in a blocking way. It will stay in the loop forever waiting for appended or prepended jobs.

=cut

sub get_job_blocking {
  my ( $self ) = @_;
  my ( $queue_name, $job ) = $self->client->blpop( $self->queue_name , 0 ); #TODO can receive a value that can serve as a timeout and can make the process stop... this way a cronjob could restart the jobs processor whenever necessary
  return $self->_analyse_job( $job );
}

=head2 size

Returns the total number of keys stored in the hash. 

The total number of keys should be also the total number of jobs in the queue.

=cut

sub size {
  my ( $self ) = @_; 
  return $self->client->hlen( $self->hash_name );
}


1;
