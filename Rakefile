require "bundler/gem_tasks"
require "rspec/core/rake_task"

namespace :test do
  desc 'Run tasks tests'
  RSpec::Core::RakeTask.new :unit do |test, args|
    test.pattern = Dir['spec/**/*_spec.rb']
    test.rspec_opts = args.extras.map { |tag| "--tag #{tag}" }
    test.rspec_opts << '--order random'
  end
end

task :default => :test
