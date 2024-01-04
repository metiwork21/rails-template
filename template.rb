# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength
RAILS_52 = '~> 5.2.1'
RAILS_71 = '~> 7.1.1'

Rails_52_requirement = Gem::Requirement.new(RAILS_52)
Rails_71_requirement = Gem::Requirement.new(RAILS_71)

require 'bundler'
require 'json'

# Add this template directory to source_paths so that Thor actions like
# copy_file and template resolve against our source files. If this file was
# invoked remotely via HTTP, that means the files are not present locally.
# In that case, use `git clone` to download them to a local temporary dir.

require 'fileutils'
require 'shellwords'

def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require 'tmpdir'
    source_paths.unshift(tempdir = Dir.mktmpdir('rails-template-'))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      '--quiet',
      'https://gitlab.com/metiwork21/rails-template.git',
      tempdir
    ].map(&:shellescape).join(' ')

    if (branch = __FILE__[%r{rails-template/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git checkout: branch }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def apply_template!
  add_template_repository_to_source_path

  case Gem::Version.new(Rails::VERSION::STRING)
  when Rails_52_requirement
    apply 'templ52.rb'
  when Rails_71_requirement
    apply 'templ71.rb'
  else
    apply 'templdef.rb'
  end
end

apply_template!

# rubocop:enable Metrics/MethodLength
