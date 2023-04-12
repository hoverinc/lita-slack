# -*- encoding: utf-8 -*-
# stub: shopify-lita-slack 6.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "shopify-lita-slack".freeze
  s.version = "6.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "lita_plugin_type" => "adapter" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ryan Brushett".freeze, "Ridwan Sharif".freeze]
  s.date = "2023-03-15"
  s.description = "Lita adapter for Slack.".freeze
  s.files = [".gitignore".freeze, ".semver".freeze, ".travis.yml".freeze, "CHANGELOG.md".freeze, "Gemfile".freeze, "LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "circle.yml".freeze, "dev.yml".freeze, "lib/lita/adapters/slack.rb".freeze, "lib/lita/adapters/slack/api.rb".freeze, "lib/lita/adapters/slack/attachment.rb".freeze, "lib/lita/adapters/slack/chat_service.rb".freeze, "lib/lita/adapters/slack/event_loop.rb".freeze, "lib/lita/adapters/slack/im_mapping.rb".freeze, "lib/lita/adapters/slack/message_handler.rb".freeze, "lib/lita/adapters/slack/room_creator.rb".freeze, "lib/lita/adapters/slack/rtm_connection.rb".freeze, "lib/lita/adapters/slack/slack_channel.rb".freeze, "lib/lita/adapters/slack/slack_im.rb".freeze, "lib/lita/adapters/slack/slack_source.rb".freeze, "lib/lita/adapters/slack/slack_user.rb".freeze, "lib/lita/adapters/slack/team_data.rb".freeze, "lib/lita/adapters/slack/user_creator.rb".freeze, "lib/shopify-lita-slack.rb".freeze, "lita-slack.gemspec".freeze, "locales/en.yml".freeze, "railgun.yml".freeze, "shipit.yml".freeze, "spec/lita/adapters/slack/api_spec.rb".freeze, "spec/lita/adapters/slack/chat_service_spec.rb".freeze, "spec/lita/adapters/slack/event_loop_spec.rb".freeze, "spec/lita/adapters/slack/im_mapping_spec.rb".freeze, "spec/lita/adapters/slack/message_handler_spec.rb".freeze, "spec/lita/adapters/slack/room_creator_spec.rb".freeze, "spec/lita/adapters/slack/rtm_connection_spec.rb".freeze, "spec/lita/adapters/slack/slack_channel_spec.rb".freeze, "spec/lita/adapters/slack/slack_im_spec.rb".freeze, "spec/lita/adapters/slack/slack_source_spec.rb".freeze, "spec/lita/adapters/slack/slack_user_spec.rb".freeze, "spec/lita/adapters/slack/user_creator_spec.rb".freeze, "spec/lita/adapters/slack_spec.rb".freeze, "spec/spec_helper.rb".freeze]
  s.homepage = "https://github.com/Shopify/lita-slack".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.8".freeze
  s.summary = "Lita adapter for Slack.".freeze
  s.test_files = ["spec/lita/adapters/slack/api_spec.rb".freeze, "spec/lita/adapters/slack/chat_service_spec.rb".freeze, "spec/lita/adapters/slack/event_loop_spec.rb".freeze, "spec/lita/adapters/slack/im_mapping_spec.rb".freeze, "spec/lita/adapters/slack/message_handler_spec.rb".freeze, "spec/lita/adapters/slack/room_creator_spec.rb".freeze, "spec/lita/adapters/slack/rtm_connection_spec.rb".freeze, "spec/lita/adapters/slack/slack_channel_spec.rb".freeze, "spec/lita/adapters/slack/slack_im_spec.rb".freeze, "spec/lita/adapters/slack/slack_source_spec.rb".freeze, "spec/lita/adapters/slack/slack_user_spec.rb".freeze, "spec/lita/adapters/slack/user_creator_spec.rb".freeze, "spec/lita/adapters/slack_spec.rb".freeze, "spec/spec_helper.rb".freeze]

  s.installed_by_version = "3.4.8" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<eventmachine>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<faraday>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<faye-websocket>.freeze, [">= 0.8.0"])
  s.add_runtime_dependency(%q<lita>.freeze, [">= 4.8"])
  s.add_runtime_dependency(%q<multi_json>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<sentry-ruby>.freeze, [">= 0"])
  s.add_development_dependency(%q<pry-byebug>.freeze, [">= 0"])
  s.add_development_dependency(%q<rack-test>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 3.0.0"])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
  s.add_development_dependency(%q<simplecov-cobertura>.freeze, [">= 0"])
end
