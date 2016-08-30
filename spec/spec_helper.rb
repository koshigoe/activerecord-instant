$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'activerecord/instant'
require 'database_cleaner'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
