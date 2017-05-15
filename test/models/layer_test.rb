require 'test_helper'

class LayerTest < ActiveSupport::TestCase
  test 'should not save' do
    layer = Layer.new
    assert_not layer.save, 'Saved without required fields'
  end
end
