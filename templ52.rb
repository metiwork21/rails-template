# frozen_string_literal: true

after_bundle do
  git add: '.'
  git commit: " -m 'Initial commit'"
end
