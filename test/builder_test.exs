defmodule AutoLinker.BuilderTest do
  use ExUnit.Case
  doctest AutoLinker.Builder

  import AutoLinker.Builder

  describe "create_phone_link" do
    test "finishes" do
      assert create_phone_link([], "", []) == ""
    end

    test "handles one link" do
      phrase = "my exten is x888. Call me."

      expected =
        ~s'my exten is <a href="#" class="phone-number" data-phone="888">x888</a>. Call me.'

      assert create_phone_link([["x888", ""]], phrase, []) == expected
    end

    test "handles multiple links" do
      phrase = "555.555.5555 or (555) 888-8888"

      expected =
        ~s'<a href="#" class="phone-number" data-phone="5555555555">555.555.5555</a> or ' <>
          ~s'<a href="#" class="phone-number" data-phone="5558888888">(555) 888-8888</a>'

      assert create_phone_link([["555.555.5555", ""], ["(555) 888-8888"]], phrase, []) == expected
    end
  end
end
