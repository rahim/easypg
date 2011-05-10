# OverrideRakeTask
Rake::TaskManager.class_eval do
  def remove_task(task_name)
    @tasks.delete(task_name.to_s)
  end
end
 
def remove_task(task_name)
  Rake.application.remove_task(task_name)
end

def override_task(args, &block)
  name, deps = Rake.application.resolve_args([args])  
  remove_task Rake.application[name].name
  task(args, &block)
end

def pg_command
    #UGLY. Find better way of doing this.       
    cmd = `psql -U postgres #{'-h 127.0.0.1' if RUBY_PLATFORM.include? "cygwin"}`
    begin
            open(cmd, 'w+') do |psql| end
    rescue
        puts 'postgres user not found - trying linux user'
        cmd = "|sudo -u postgres psql #{'-h 127.0.0.1' if RUBY_PLATFORM.include? "cygwin"}"
        begin
          open(cmd, 'w+') do |psql| end
        rescue
          raise "Can't find postgres user. Create database manually"
        end
    end

   cmd
end



namespace :db do
  override_task :create => :load_config do
    puts "db:create overriden!"
    easypg_create_database(ActiveRecord::Base.configurations[::Rails.env])
  end
  
  # ideally we'd like to refer to reuse the original create_database where appropriate
  # however we seem to have no way of referencing it =(
  # aliasing doesn't seem to be a workable approach here due to way rake files are evaluated
  # (and the results scoped)
  
  def easypg_create_database(config)
    if config['adapter'] == 'postgresql' and not ::Rails.env =~ /production/ 
      postgres_setup(config['username'], config['database'], config['password'])
    else
      create_database(config)
    end
  end

  SQL_TEMPLATE = "DROP DATABASE IF EXISTS %DATABASE%; DROP ROLE IF EXISTS %USER%;\
                  CREATE ROLE %USER% LOGIN UNENCRYPTED PASSWORD '%PASSWORD%' SUPERUSER NOINHERIT NOCREATEDB NOCREATEROLE;\
                  CREATE DATABASE %DATABASE% WITH OWNER = postgres ENCODING = 'UTF8' TABLESPACE = pg_default;\
                  GRANT ALL ON DATABASE %DATABASE% TO %USER%;"
  
  def postgres_setup(user, database, password)
    sql = SQL_TEMPLATE.clone
    sql.gsub!("%USER%", user)
    sql.gsub!("%DATABASE%", database)
    sql.gsub!("%PASSWORD%", password)
    # sh "echo \"#{sql}\" | psql -U postgres #{'-h 127.0.0.1' if RUBY_PLATFORM.include? "cygwin"}"
    
    
    open(pg_command, 'w+') do |psql|
      psql.write(sql)
      psql.close_write
      psql.read.split("\n").each do |l|
        puts "[psql] #{l}"
      end
    end
  end
  
  namespace :create do
    override_task :all => :load_config do
      configs = ActiveRecord::Base.configurations.clone
      configs.delete 'production'
      configs.delete 'staging'
      # TODO: could remove duplicate host/database pairs (eg cucumber)
      configs.each_value do |config|
        next unless config['database'] && 
        local_database?(config) { easypg_create_database(config) }
      end
    end
  end
  
end
