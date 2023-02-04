require "test_helper"

describe NucleusRails do
  describe "NucleusCore configuration" do
    it "sets expected properties" do
      exceptions = NucleusCore.configuration.exceptions_map

      assert_equal([ActiveRecord::RecordNotFound], exceptions.not_found)
      assert_equal([ActiveRecord::ActiveRecordError], exceptions.unprocessable)
    end
  end
end
