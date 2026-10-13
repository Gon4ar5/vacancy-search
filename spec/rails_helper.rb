ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
abort("The RSpec suite cannot run in production") if Rails.env.production?
require "rspec/rails"

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
end
