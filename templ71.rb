# frozen_string_literal: true

def generate_rubocop_yml!
  copy_file 'rubocop.yml', '.rubocop.yml'
end

def install_development_gem!
  %w[
    rubocop-rails
    erb_lint
    ffaker
    solargraph
    ruby-lsp
    haml_lint
  ].each { |gemname| run "bundle add #{gemname} --group=development" }

  generate_rubocop_yml!
end

def install_internationalization!
  %w[rails-i18n http_accept_language].each { |gemname| run "bundle add #{gemname}" }

  initializer 'i18n.rb', <<~CODE
    Rails.application.config.i18n.default_locale = :en
    Rails.application.config.i18n.available_locales = %w[en ru]
    Rails.application.config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]

  CODE

  inject_into_class 'app/controllers/application_controller.rb', 'ApplicationController' do
    "  include HttpAcceptLanguage::AutoLocale\n"
  end
end

def install_haml!
  %w[haml haml-rails].each { |gemname| run "bundle add #{gemname}" }
end

def install_additional_gems!
  install_internationalization!
  install_haml!
end

# rubocop:disable Metrics/MethodLength
def install_font_awesome!
  %w[
    @fortawesome/fontawesome-free
  ].each { |pack| run "yarn add #{pack}" }

  insert_into_file('app/assets/stylesheets/application.bootstrap.scss', before: /\z/) do
    <<~SCSSCODE
      $fa-font-path: "./fontawesome-free/webfonts";
      @import "@fortawesome/fontawesome-free/scss/fontawesome";
      @import "@fortawesome/fontawesome-free/scss/solid";
    SCSSCODE
  end

  append_to_file('app/javascript/application.js') do
    <<~JSCODE
      // import "@fortawesome/fontawesome-free";
    JSCODE
  end

  initializer 'fontawesome.rb', <<~CODE
    Rails.application.config.assets.paths << Rails.root.join("node_modules/@fortawesome")
  CODE
end

require_relative 'old_firefox'

def install_additional_js_packs!
  %w[
    @rails/request.js
  ].each { |pack| run "yarn add #{pack}" }

  install_old_firefox_support!
  install_font_awesome!
end

after_bundle do
  install_development_gem!

  install_additional_gems!

  install_additional_js_packs!

  gsub_file 'Procfile.dev', 'env RUBY_DEBUG_OPEN=true bin/rails server', 'bin/rails server -b 0.0.0.0 -p 3000'

  generate 'controller', 'home', 'index'

  route "root 'home#index'"

  git add: '.'
  git commit: " -m 'Initial commit'"
end
# rubocop:enable Metrics/MethodLength
