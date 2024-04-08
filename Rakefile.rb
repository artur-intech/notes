# frozen_string_literal: true

require 'minitest/test_task'

import 'app.rb'

Minitest::TestTask.create do |t|
  t.framework = %(require "test/test_helper.rb")
  t.libs = %w[test .]
  t.test_globs = ['test/**/*_test.rb']
end
