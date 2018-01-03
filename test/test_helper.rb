$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'numerizer'

require 'minitest/autorun'

class TestCase < Minitest::Test
end
