require 'test_helper'

require 'i18n/tasks'

class I18nTest < ActiveSupport::TestCase
  test 'should not have missing keys' do
    translation = I18n::Tasks::BaseTask.new(locales: [:en, :fr])
    missing_keys = translation.missing_keys
    # unused_keys = translation.unused_keys

    assert_equal missing_keys.leaves.count, 0
  end
end
