#######################################################################################################
# Substantial portions of this code were adapted from the Radiant CMS project (http://radiantcms.org) #
#######################################################################################################
namespace :db do
  desc "Migrate schema to version 0 and back up again. WARNING: Destroys all data in tables!!"
  task :remigrate => :environment do
    require 'highline/import'
    if ENV['SKIP_NAG'] or ENV['OVERWRITE'].to_s.downcase == 'true' or agree("This task will destroy any data in the database. Are you sure you want to \ncontinue? [yn] ")

      ENV['SKIP_NAG'] = 'yes'
      
      # Migrate downward
      ActiveRecord::Migrator.migrate("#{SPREE_ROOT}/db/migrate/", 0)
    
      # Migrate upward 
      Rake::Task["db:migrate"].invoke
      
      # Dump the schema
      Rake::Task["db:schema:dump"].invoke
    else
      say "Task cancelled."
      exit
    end
  end
  
  desc "Bootstrap your database for Spree."
  task :bootstrap  do
    require 'highline/import'
    if ENV['SKIP_NAG'] or agree("This task will destroy any data in the database. Are you sure you want to \ncontinue? [yn] ")
      # Migrate downward
      ENV['SKIP_NAG'] = 'yes'
      Rake::Task["db:migrate:extensions:zero"].invoke
      ActiveRecord::Migrator.migrate("#{SPREE_ROOT}/db/migrate/", 0)

      # Migrate upward 
      ActiveRecord::Migrator.migrate("#{SPREE_ROOT}/db/migrate/")
      Rake::Task["db:migrate:extensions"].invoke    
    
      # Dump the schema
      Rake::Task["db:schema:dump"].invoke

      require 'spree/setup'
      Spree::Setup.bootstrap(
        :admin_name => ENV['ADMIN_NAME'],
        :admin_username => ENV['ADMIN_USERNAME'],
        :admin_password => ENV['ADMIN_PASSWORD'],
        :admin_email => ENV['ADMIN_EMAIL'],
        :database_template => ENV['DATABASE_TEMPLATE']
      )
    else
      say "Task cancelled."
      exit
    end
  end
end