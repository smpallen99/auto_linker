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

  describe "TLDs" do
    test "parse with scheme" do
      text = "https://google.com"

      expected =
        "<a href='https://google.com' class='auto-linker' target='_blank' rel='noopener noreferrer'>google.com</a>"

      assert AutoLinker.link(text, scheme: true) == expected
    end

    test "only existing TLDs with scheme" do
      text = "this url https://google.foobar.blah11blah/ has invalid TLD"

      expected = "this url https://google.foobar.blah11blah/ has invalid TLD"
      assert AutoLinker.link(text, scheme: true) == expected

      text = "this url https://google.foobar.com/ has valid TLD"

      expected =
        "this url <a href='https://google.foobar.com/' class='auto-linker' target='_blank' rel='noopener noreferrer'>google.foobar.com/</a> has valid TLD"

      assert AutoLinker.link(text, scheme: true) == expected
    end

    test "only existing TLDs without scheme" do
      text = "this url google.foobar.blah11blah/ has invalid TLD"
      expected = "this url google.foobar.blah11blah/ has invalid TLD"
      assert AutoLinker.link(text, scheme: false) == expected

      text = "this url google.foobar.com/ has valid TLD"

      expected =
        "this url <a href='http://google.foobar.com/' class='auto-linker' target='_blank' rel='noopener noreferrer'>google.foobar.com/</a> has valid TLD"

      assert AutoLinker.link(text, scheme: false) == expected
    end

    test "only existing TLDs with and without scheme" do
      text = "this url http://google.foobar.com/ has valid TLD"

      expected =
        "this url <a href='http://google.foobar.com/' class='auto-linker' target='_blank' rel='noopener noreferrer'>google.foobar.com/</a> has valid TLD"

      assert AutoLinker.link(text, scheme: true) == expected

      text = "this url google.foobar.com/ has valid TLD"

      expected =
        "this url <a href='http://google.foobar.com/' class='auto-linker' target='_blank' rel='noopener noreferrer'>google.foobar.com/</a> has valid TLD"

      assert AutoLinker.link(text, scheme: true) == expected
    end
  end
end
