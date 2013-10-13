## 

receives something like:

{
  id => 21876931,
  job => {
      'plugin' => 'montage\_image',
      data => {
          bla => 'and all the necessary stuff this job might need'
      }
  }
}

# NAME

Distributed::Tasks::Queue - Distributable scalable jobs / tasks processing

# SYNOPSIS

    use strict;
    use Test::More;
    use Distributed::Tasks::Queue;
    use lib './t/lib/';
    use Plugins::TestOnly;
    use Data::Printer;;

    # replace with the actual test
    ok 1;

    my $jobs_adder  = Distributed::Tasks::Queue->new( plugin_list => [ qw/Plugins::TestOnly/ ] );
    my $jobs_worker = Distributed::Tasks::Queue->new( plugin_list => [ qw/Plugins::TestOnly/ ] );

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

# DESCRIPTION

Distributed::Tasks::Queue allows you to queue jobs / tasks that can be processed later.

The distributed tasks queue allows your application to insert a task into a queue. The task must include all the details regarding the task. That will make the task independent and self describing. 

That way you can create a plugin to process each task. Every task must include the plugin name that will handle that task. You should create one plugin for each task. The plugin will receive an object(hash) that you inserted into the queue. That object must have all the information it needs to be processed by your plugin. Yout plugin can do whatever... save into a directory, insert into database, etc.

It will use a redis engine by default but you should be able to create a similar backend queue custom class and override the engine.

# AUTHOR

Hernan Lopes <hernan@cpan.org>

# COPYRIGHT

Copyright 2013 - Hernan Lopes

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO
