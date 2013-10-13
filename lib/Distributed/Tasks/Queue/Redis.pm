package Distributed::Tasks::Queue::Redis;
use Moose;
use JSON::XS;

has queue_name => ( is => 'rw', default => sub { "imovelcity_jobs" }  );
has hash_name  => ( is => 'rw', default => sub { "imovelcity_hash" }  );
has [ qw/client expiration_time/]     => ( is => 'rw' );

sub is_visited {
    my ( $self, $robot, $url ) = @_;
    my $is_visited = $self->client->hget(
      $self->url_visited , $url
    );    #TODO: deve ficar no arquivo de config dentro da secao redis.
    return 1 if defined $is_visited and $is_visited ne '';
    return 0;
}


sub insert_on_end {
    my ( $self, $args ) = @_;
    my $count_items = $self->client->rpush(
        $self->queue_name
        , encode_json( {
            id  => $args->{id},
            job => $args->{job},
        } )
    );
    $self->client->setex( $args->{ id }, $self->expiration_time, "job id saved for some seconds and will expire" );
}

sub insert_on_begining {
    my ( $self, $args ) = @_;
    my $count_items = $self->client->lpush( 
        $self->queue_name ,
        encode_json( {
            id  => $args->{id},
            job => $args->{job},
        } )
    );
    $self->client->setex( $args->{ id }, $self->expiration_time, "job id saved for some seconds and will expire" );
}

sub append {
  my ( $self, $args ) = @_;
  if ( !$self->client->get( $args->{ id } ) ) {
      $self->insert_on_end( $args );
      return 1;
  }
  return 0;
}

sub prepend {
    my ( $self, $args ) = @_; #args = { id => $id, job => $job, expire_date => '...' }
    if ( !$self->client->get( $args->{ id } ) ) {
        $self->insert_on_begining( $args );
        return 1;
    }
    return 0;
}

sub analyse_job {
    my ( $self, $job ) = @_; 
    if ( defined $job ) {
      my $job = decode_json ( $job );
      if ( exists $job->{ id } ) {
        $self->client->del( $job->{ id } );
        return $job;
      }
    }
    return 0;
}

sub get {
    my ( $self ) = @_;
    my $job = $self->client->lpop( $self->queue_name );
    return $self->analyse_job( $job );
}

sub get_job_blocking {
  my ( $self ) = @_;
  my ( $queue_name, $job ) = $self->client->blpop( $self->queue_name , 0 ); #TODO can receive a value that can serve as a timeout and can make the process stop... this way a cronjob could restart the jobs processor whenever necessary
  return $self->analyse_job( $job );
}


1;
