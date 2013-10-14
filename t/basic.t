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
warn "RES: $res";

$jobs_worker->get_jobs( );

done_testing;
