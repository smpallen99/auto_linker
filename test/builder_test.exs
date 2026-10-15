defmodule AutoLinker.BuilderTest do
  use ExUnit.Case
  doctest AutoLinker.Builder

  alias AutoLinker.Builder

  describe "create_phone_link" do
    test "finishes" do
      assert Builder.create_phone_link([], "", []) == ""
    end

    test "handles one link" do
      phrase = "my exten is x888. Call me."

      expected =
        ~s'my exten is <a href="#" class="phone-number" data-phone="888">x888</a>. Call me.'

      assert Builder.create_phone_link([["x888", ""]], phrase, []) == expected
    end

    test "handles multiple links" do
      phrase = "555.555.5555 or (555) 888-8888"

      expected =
        ~s'<a href="#" class="phone-number" data-phone="5555555555">555.555.5555</a> or ' <>
          ~s'<a href="#" class="phone-number" data-phone="5558888888">(555) 888-8888</a>'

      assert Builder.create_phone_link([["555.555.5555", ""], ["(555) 888-8888"]], phrase, []) ==
               expected
    end
  end

  describe "format_phone_link" do
    test "default opts" do
      assert Builder.format_phone_link("5551235467", "(555) 123-4567", []) ==
               "<a href=\"#\" class=\"phone-number\" data-phone=\"5551235467\">(555) 123-4567</a>"

      assert Builder.format_phone_link("5551235467", "(555) 123-4567",
               class: "pn",
               data_phone: "data-pn",
               href: "#pn",
               attributes: ["data-x": "xx", xyz: true]
             ) ==
               "<a href=\"#pn\" class=\"pn\" data-pn=\"5551235467\" data-x=\"xx\" xyz=\"true\">(555) 123-4567</a>"
    end
  end
end
