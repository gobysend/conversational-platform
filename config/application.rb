# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Chatwoot
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    config.eager_load_paths << Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('enterprise/lib')
    config.eager_load_paths += Dir["#{Rails.root}/enterprise/app/**"]
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.generators.javascripts = false
    config.generators.stylesheets = false

    # Custom chatwoot configurations
    config.x = config_for(:app).with_indifferent_access

    # Set default locale
    config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
    config.i18n.default_locale = :vi
  end

  def self.config
    @config ||= Rails.configuration.x
  end
end
