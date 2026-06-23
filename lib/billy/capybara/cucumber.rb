# frozen_string_literal: true

require 'capybara/cucumber'
require 'billy/browsers/capybara'
require 'billy/init/cucumber'

Billy::Browsers::Capybara.register_drivers
