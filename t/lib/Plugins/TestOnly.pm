package Plugins::TestOnly;
use Moose;
#ABSTRACT: For testing purposes only. This plugin will transform a text as a job processing example.

has caller          => ( is => 'rw' );
has exports_method  => ( is => 'rw', default => sub { return 'test_only' } );

sub test_only {
  my ( $self, $job ) = @_; #action: add, list delete , etc
  warn "PROCESSING JOB...................................................";
  use DDP;
  warn p $job;
  warn "DO WHATEVER............................... the job must be independent and have every instruction it needs to be executed";
  if ( $job->{ description }->{ action } eq 'duplicate_text' ) {
    #do whatever.. save on  disk etc
    my $final_text   = $job->{description}->{text}.$job->{description}->{text};
    $job->{ result } = $final_text;
    warn $final_text;
    warn "^^ FROM JOB PROCESS";
  }
}

sub validate {
  my ( $self, $job ) = @_; 
}

1;
