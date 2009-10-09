Easypg
======

Not to be confused with *that* [EasyPG](http://www.easypg.org/)

This rails plugin overrides rake db:create, db:create:all smoothing the development database
setup process when postgres is used with database specific users rather than a generic superuser.

Warning: the plugin makes db:create's behaviour more aggressive - dropping the existing
database or user if they exist already. Be careful if you value the content stored in
your development database!

Example
-------

in rails project:

    $ ruby script/plugin install http://github.com/rahim/easypg.git/

then when another dev comes along to the rails project afresh:

    $ svn co http://svn/repos/awesomest_rails_project/trunk awesomest_rails_project
    $ cd awesomest_rails_project
    $ rake db:setup

this should now work without any manual database administration to set up users/permissions etc
(same is true of db:create, db:create:all, db:reset)


Known issues
------------

* postgres-pr has a known issue with rails 2.3.x versions, see http://github.com/mneumann/postgres-pr/issues#issue/1
  the workaround for this may need to be loaded in the rake environment (not just rails init)
  for tasks to function correctly
* db:reset fails with an auth error if the database user doens't yet exist 
* The default database.yml refers to only one user. Our script will probably fail using this
  approach as the user may be associated with another database when the script tries to drop them.
* There's currently no uninstall script which means the plugin leaves behind a stray reference to
  override_rake_task in the Rakefile when it's uninstalled

Future
------

* override db:drop to avoid the permissions issue described above
* The plugin currently contains the override rake task plugin. It may be more
  appropriate for it to install this separately as part of the install script.
* installing a plugin just to clean up database handling feels invasive, a gem that adds some 
  sake tasks to work with the rails' tasks might be a cleaner approach


Copyright (c) 2009 Rahim Packir Saibo, under the MIT license


---

Override RakeTask
=================

OverrideRakeTask plugin by Eugene Bolshakov, eugene.bolshakov@gmail.com, http://www.taknado.com

This plugin is based on the Matthew Bass's idea described here:
http://matthewbass.com/2007/03/07/overriding-existing-rake-tasks/

The installation script is based on the one found in the app_config plugin
by Daniel Owsianski, http://jarmark.org/projects/app-config/

When using rake with rails it loads the task in the following order:

1. Default rails tasks (like db:migrate)
2. The tasks in your app's lib/tasks directory
3. The tasks in your vendor/plugins directory

This plugin will allow to override rake tasks that were defined earlier. It means that 
you'll be able to override default rails tasks with lib/tasks & plugins tasks and 
override the taksks in lib/tasks with the tasks defined in plugins.

In order to override a task you need to define it as usual, but using "override_task" 
method instead of "task":

    namespace :db do
      override_task :migrate do
        ...
      end
    end

In order to make this work the plugin should be loaded before the tasks and the install script
supplied with the plugin adds a line to load itself to the Rakefile. If it won't be able to 
modify your Rakefile, it will let you know and you'll have to modify it manually.
