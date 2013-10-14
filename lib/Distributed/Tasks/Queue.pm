package Distributed::Tasks::Queue;
use Moose;
#use Class::Load ':all';
use Distributed::Tasks::Queue::Redis;

use 5.008_005;
our $VERSION = '0.01';
use Redis::Client;

has queue => (
  is        => 'rw', 
  default   => sub {
    return Distributed::Tasks::Queue::Redis->new(
      queue_name        => "my_jobs", 
      hash_name         => "my_hash", 
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

An $job looks like:

  {
    id  => 21876931,
    job => {
        'plugin' => 'plugin_method',
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
#       my $class = load_class( $_ );
#       my $instance = $class->new( caller => $self );
        $_->caller( $self );
        $self->plugins->{ $_->exports_method } = $_
            if defined $_->exports_method
               and ! exists $self->plugins->{ $_->exports_method }
        } @{ $self->plugin_list };
}


1;
__END__

=encoding utf-8

=head1 NAME

Distributed::Tasks::Queue - Distributable scalable jobs / tasks processing

=head1 SYNOPSIS

  use strict;
  use Distributed::Tasks::Queue;
  use Plugins::TestOnly;
  use Data::Printer;

  # replace with the actual test
  my $jobs_adder  = Distributed::Tasks::Queue->new( plugin_list => [ Plugins::TestOnly->new() ] );
  my $jobs_worker = Distributed::Tasks::Queue->new( plugin_list => [ Plugins::TestOnly->new ] );

  my $job = {
      id => 'test_job_one',
      job => {
          plugin  => 'test_only',
          data    => {
              text    => "To be processed!",
              action  => 'duplicate_text'
          }
      }
  };
  my $res = $jobs_adder->append( $job );

  $jobs_worker->get_jobs( );

and in your plugin, named Plugins::TestOnly

  package Plugins::TestOnly;
  use Moose;
  #ABSTRACT: For testing purposes only. This plugin will transform a text as a job processing example.

  has caller          => ( is => 'rw' );
  has exports_method  => ( is => 'rw', default => sub { return 'test_only' } );

  sub test_only {
    my ( $self, $job, $action ) = @_; #action: add, list delete , etc
    my $actions = {
      process => sub {
        my ( $self, $job ) = @_;
        warn "PROCESSING JOB...................................................";
        use DDP;
        warn p $job;
        warn "DO WHATEVER............................... the job must be independent and have every instruction it needs to be executed";
        if ( $job->{ job }->{ data }->{ action } eq 'duplicate_text' ) {
          #do whatever.. save on  disk etc
          my $final_text   = $job->{job}->{data}->{text}.$job->{job}->{data}->{text};
          $job->{ result } = $final_text;
          warn $final_text;
          warn "^^ FROM JOB PROCESS";
        }
      }
    };
    $actions->{ $action }->( $self, $job );
  }

  sub validate {
    my ( $self, $job ) = @_; 
  }

  1;

=head1 DESCRIPTION

Distributed::Tasks::Queue allows you to queue jobs / tasks that can be processed later.

The distributed tasks queue allows your application to insert a task into a queue. The task must include all the details regarding the task. That will make the task independent and self describing. 

That way you can create a plugin to process each task. Every task must include the plugin name that will handle that task. You should create one plugin for each task. The plugin will receive an object(hash) that you inserted into the queue. That object must have all the information it needs to be processed by your plugin. Your plugin can do whatever... save into a directory, insert into database, etc.

It will use a redis engine by default but you should be able to create a similar backend queue custom class and override the engine. You should be able to override any default atributes also.



=head1 AUTHOR

Hernan Lopes E<lt>hernan@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013 - Hernan Lopes

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
