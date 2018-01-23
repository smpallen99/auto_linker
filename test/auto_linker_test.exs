defmodule AutoLinkerTest do
  use ExUnit.Case
  doctest AutoLinker


  test "phone number" do
    assert AutoLinker.link(", work (555) 555-5555", phone: true) ==
      ~s{, work <a href="#" class="phone-number" data-phone="5555555555">(555) 555-5555</a>}
  end

  test "default link" do
    assert AutoLinker.link("google.com") ==
      "<a href='http://google.com' class='auto-linker' target='_blank' rel='noopener noreferrer'>google.com</a>"
  end

  test "markdown" do
    assert AutoLinker.link("[google.com](http://google.com)", markdown: true) ==
      "<a href='http://google.com' class='auto-linker' target='_blank' rel='noopener noreferrer'>google.com</a>"
  end

  test "does on link existing links" do
    assert AutoLinker.link("<a href='http://google.com'>google.com</a>") ==
      "<a href='http://google.com'>google.com</a>"
  end

  test "phone number and markdown link" do
    assert AutoLinker.link("888 888-8888  [ab](a.com)", phone: true, markdown: true) ==
      "<a href=\"#\" class=\"phone-number\" data-phone=\"8888888888\">888 888-8888</a>" <>
      "  <a href='a.com' class='auto-linker' target='_blank' rel='noopener noreferrer'>ab</a>"
  end

end
