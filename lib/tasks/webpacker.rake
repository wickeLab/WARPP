# frozen_string_literal: true

namespace :webpacker do
  task :check_npm do
    npm_version = `npm --version`

    version = Gem::Version.new(npm_version)
    package_json_path = Pathname.new("#{Rails.root}/package.json").realpath
    npm_requirement = JSON.parse(package_json_path.read).dig('engines', 'npm')
    requirement = Gem::Requirement.new(npm_requirement)

    $stderr.puts exit! unless requirement.satisfied_by?(version)
  end

  task :npm_install do
    system 'npm install'
  end
end
