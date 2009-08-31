# coding: utf-8

class TracksVisitsMigrationGenerator < Rails::Generator::Base
  
  def manifest
    record do |m|
      m.migration_template 'migration.rb',
        File.join('db', 'migrate'), :migration_file_name => 'tracks_visits_migration'
    end
  end
  
end