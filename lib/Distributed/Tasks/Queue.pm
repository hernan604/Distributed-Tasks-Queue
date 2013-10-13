package Distributed::Tasks::Queue;
use Moose;
use Class::Load ':all';
use Distributed::Tasks::Queue::Redis;

use 5.008_005;
our $VERSION = '0.01';
use Redis::Client;

has queue => (
  is        => 'rw', 
  default   => sub {
    return Distributed::Tasks::Queue::Redis->new(
      queue_name        => "imovelcity_jobs", 
      hash_name         => "imovelcity_hash", 
      expiration_time   => 10,
      client            => Redis::Client->new( host => 'localhost', port => 6379 ),
    )
  }
);

has plugins => (
  is      => "rw",
  default => sub { { } }
);

has plugin_list => (
  is        => 'rw',
  default   => sub { [ qw/
      WWW::Imovelcity::Jobs::Plugins::MontageImage
  / ] }
);

sub get_jobs {
    my ( $self ) = @_;
    while ( my $job = $self->queue->get( ) ) {
        $self->process( $job );
    }
}

sub get_job_blocking {
    my ( $self ) = @_;
    while ( my $job = $self->queue->get_job_blocking( ) ) {
        $self->process( $job );
    }
}

sub block_get {
    my ( $self ) = @_; 
    return $self->queue->block_get();
}

=head2

receives something like:

{
  id => 21876931,
  job => {
      'plugin' => 'montage_image',
      data => {
          bla => 'and all the necessary stuff this job might need'
      }
  }
}

=cut

sub append {
    my ( $self, $args ) = @_; 
    return $self->queue->append( $args ) 
        if $self->can_process( $args->{ job }->{ plugin } );
}

sub prepend {
    my ( $self, $args ) = @_; 
    return $self->queue->prepend( $args ) 
        if $self->can_process( $args->{ job }->{ plugin } );
}

sub process {
    my ( $self, $job ) = @_; 
    my $j     = $job->{ job };
    if ( $self->can_process( $j->{ plugin } ) ) {
      my $export_name = $j->{ plugin };
      $self->plugins->{ $j->{ plugin } }->$export_name( $job, 'process' );
    }
}

sub can_process {
    my ( $self, $plugin ) = @_; 
    return exists $self->plugins->{ $plugin };
}

sub BUILD {
    my ( $self ) = @_;
    map {
        my $class = load_class( $_ );
        my $instance = $class->new( caller => $self );
        $self->plugins->{ $instance->exports_method } = $instance
            if defined $instance->exports_method
               and ! exists $self->plugins->{ $instance->exports_method }
        } @{ $self->plugin_list };
}


1;
__END__

=encoding utf-8

=head1 NAME

Distributed::Tasks::Queue - Distributable scalable jobs / tasks processing

=head1 SYNOPSIS

  use Distributed::Tasks::Queue;

=head1 DESCRIPTION

Distributed::Tasks::Queue is

=head1 AUTHOR

Hernan Lopes E<lt>hernan@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013 - Hernan Lopes

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
