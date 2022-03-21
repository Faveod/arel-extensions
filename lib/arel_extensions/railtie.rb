require 'rails'

module ArelExtensions
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'arel_extensions/tasks.rb'
    end
  end
end
