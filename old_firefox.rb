# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength

def write_babel_config!
  copy_file 'rails71_babel.config.js', 'babel.config.js'
end

def include_babel_in_webpack!
  insert_into_file 'webpack.config.js', after: /devtool:\s+"source-map",/ do
    <<~JSCODE

      // mode: process.env.RAILS_ENV === 'production' ? 'production' : 'development',

      module: {
        rules: [
          {
            test: /\\.(js|mjs)$/,
            include: /node_modules/,
            exclude: /(?:@?babel(?:\\/|\\\\{1,2}|-).+)|regenerator-runtime|core-js|^webpack$|^webpack-assets-manifest$|^webpack-cli$|^webpack-sources$|^@rails\\/webpacker$/,
            use: [
              {
                loader: 'babel-loader',
                options: {
                  babelrc: false,
                  presets: [['@babel/preset-env', { modules: false}]],
                  targets: { firefox: '52' },
                  cacheDirectory: true,
                  cacheCompression: true,
                  compact: false,
                  sourceMaps: false
                }
              }
            ]
          },
          {
            test: /\\.(js|jsx|mjs|ts|tsx)?(\\.erb)?$/,
            exclude: /node_modules/,
            use: [
              {
                loader: 'babel-loader',
                options: {
                  presets: [['@babel/preset-env', { modules: false }]],
                  targets: { firefox: '52' },
                  cacheDirectory: true,
                  cacheCompression: true,
                  compact: true
                }
              }
            ]
          }
        ]
      },
    JSCODE
  end
end

def install_babel!
  %w[
    @babel/core
    babel-loader
    @babel/preset-env
    babel-plugin-macros
    @babel/plugin-transform-runtime
  ].each { |pack| run "yarn add #{pack}" }

  write_babel_config!

  include_babel_in_webpack!

  run 'npm pkg set browserslist="Firefox >= 52.9"'
end

def install_js_polyfill!
  %w[
    @webcomponents/custom-elements
    abortcontroller-polyfill
    intersection-observer
    core-js
    url-search-params-polyfill
  ].each { |pack| run "yarn add #{pack}" }

  insert_into_file 'app/javascript/application.js', before: %r{import\s+"@hotwired/turbo-rails"} do
    <<~JSCODE
      import "core-js/features/array/flat-map";
      import "intersection-observer"
      import "@webcomponents/custom-elements"
      import "abortcontroller-polyfill"
      import "url-search-params-polyfill";
    JSCODE
  end
end

def install_old_firefox_support!
  install_babel!

  install_js_polyfill!
end

# rubocop:enable Metrics/MethodLength
