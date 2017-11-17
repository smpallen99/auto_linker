defmodule AutoLinkerTest do
  use ExUnit.Case
  doctest AutoLinker


  test "phone number" do
    assert AutoLinker.link(", work (555) 555-5555", phone: true) ==
      ~s{, work <a href="#" class="phone-number" data-phone="5555555555">(555) 555-5555</a>}
  end

end
