Run your Cucumber on multiple CPUs.

Setup
=====
Simple copy the rake task to `lib/tasks` in your Rails project.

Usage
-----
    RAILS_ENV=test rake salad:features

At the moment you explicitly need to set `RAILS_ENV` to `test`. The first time you run it, it will create and migrate the necessary database tables, so make sure your user for the `test` environment has privileges to create additional databases. Additional databases for the extra Cucumber processes are created by appending `_#{i}` to the test database as defined in your `config.yml`. This means it will _not_ interfere with your regular test database. You can run this task and your specs at the same time.

`Ctrl-c` aborts all running processes.

Configuration
-------------
You can configure the arguments passed to Cucumber by editing the rake task. The number of Cucumber processes is determined by the `SALAD_INSTANCES` environment variable which, if not explicitly set, defaults to 4.

It is assumed your features live under "RAILS_ROOT/features", if this is not the case you can change the `features_dir` variable in the script.

When in doubt, read the script. ;-)

Known problems
--------------
* Sometimes tests will fail, for no apparent reason at all. :(
* The first time you run it, it will create a bunch of databases, migrate them and then fail all features spectacularly... Simply quit it after migration is complete and try again.

Authors
-------
Written by Sjoerd Tieleman ([@tieleman](http://twitter.com/tieleman)) and Bart Zonneveld ([@bartzon](http://twitter.com/bartzon)), to scratch their own itch.
