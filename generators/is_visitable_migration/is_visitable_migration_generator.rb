# coding: utf-8

class IsVisitableMigrationGenerator < Rails::Generator::Base
  
  def manifest
    record do |m|
      m.migration_template 'migration.rb',
        File.join('db', 'migrate'), :migration_file_name => 'is_visitable_migration'
    end
  end
  
end