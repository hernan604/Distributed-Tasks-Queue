use strict;
use Test::More;
use Distributed::Tasks::Queue;
use lib './t/lib/';
use Plugins::TestOnly;
use Data::Printer;;

# replace with the actual test
ok 1;

my $jobs_adder  = Distributed::Tasks::Queue->new( plugin_list => [ Plugins::TestOnly->new() ] );
my $jobs_worker = Distributed::Tasks::Queue->new( plugin_list => [ Plugins::TestOnly->new() ] );

#first job to go into queue
my $job = {
    id => 'test_job_one',
    job => {
        plugin  => 'test_only',
        description    => {
            text    => "To be processed!",
            action  => 'duplicate_text'
        }
    }
};
$jobs_adder->append( $job );

#check the queue size
ok( $jobs_adder->queue_size() == 1, "One item was inserted on the queue" );

#another job
my $job2 = {
    id => 'test_job_two',
    job => {
        plugin  => 'test_only',
        description    => {
            text    => "<- Works ->",
            action  => 'duplicate_text'
        }
    }
};
$jobs_adder->append( $job2 );

#check queue size again
ok( $jobs_adder->queue_size() == 2, "One item was inserted on the queue" );

#start the worker..
$jobs_worker->get_jobs( ); #non blocking. use get_job_blocking if wanted

done_testing;
