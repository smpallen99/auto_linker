defmodule AutoLinkerTest do
  use ExUnit.Case
  doctest AutoLinker

  test "phone number" do
    assert AutoLinker.link(", work (555) 555-5555", phone: true) ==
             ~s{, work <a href="#" class="phone-number" data-phone="5555555555">(555) 555-5555</a>}
  end

  test "multiple phone numbers" do
    assert AutoLinker.link("15555555555 and 15555555554", phone: true) ==
             ~s{<a href="#" class="phone-number" data-phone="15555555555">15555555555</a> and } <>
               ~s{<a href="#" class="phone-number" data-phone="15555555554">15555555554</a>}

    assert AutoLinker.link("15555565222 and 15555565222", phone: true) ==
             ~s{<a href="#" class="phone-number" data-phone="15555565222">15555565222</a> and } <>
               ~s{<a href="#" class="phone-number" data-phone="15555565222">15555565222</a>}
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

  describe "don't autolink code blocks in markdown" do
    test "auto link phone numbers in non md block" do
      text = "```\n5555555555```"

      assert AutoLinker.link(text, phone: true) ==
               String.replace(
                 text,
                 "5555555555",
                 ~s'<a href="#" class="phone-number" data-phone="5555555555">5555555555</a>'
               )
    end

    test "autolink urls in non md block" do
      text = "```\ngoogle.com\n```"

      expected =
        String.replace(
          text,
          "google.com",
          "<a href='http://google.com' class='auto-linker' target='_blank' rel='noopener noreferrer'>google.com</a>"
        )

      assert AutoLinker.link(text) == expected
    end

    test "does not link phone numbers" do
      text = "!md\n5555555555 \n```\n5555555551\n```\nsomething\n```\ntest 5555555552\n```\n"

      assert AutoLinker.link(text, phone: true) ==
               String.replace(
                 text,
                 "5555555555",
                 ~s'<a href="#" class="phone-number" data-phone="5555555555">5555555555</a>'
               )
    end

    test "does not add leading line" do
      text = "!md\n```\n5555555555\n```"
      assert AutoLinker.link(text, phone: true) == text
    end

    test "handles no terminating ``` block" do
      text = "!md\n```5555555555"
      assert AutoLinker.link(text, phone: true) == text
    end

    test "does not autolink urls in md block" do
      text = "!md\n```\ngoogle.com```"
      assert AutoLinker.link(text) == text
    end
  end

  describe "mixed links" do
    test "phone and link" do
      text = "test google.com @ x555"
      expected = "test <a href='http://google.com'>google.com</a> @ <a href=\"#\" class=\"phone-number\" data-phone=\"555\">x555</a>"
      assert AutoLinker.link(text, phone: true, rel: false, new_window: false, class: false) == expected
    end

    test "no phone and link" do
      text = "test google.com @ x555"
      expected = "test <a href='http://google.com'>google.com</a> @ x555"
      assert AutoLinker.link(text, phone: false, rel: false, new_window: false, class: false) == expected
    end

    test "phone and truncate 10" do
      text = "1-555-555-5555 and maps.google.com"
      expected = "<a href=\"#\" class=\"phone-number\" data-phone=\"15555555555\">1-555-555-5555</a> and <a href='http://maps.google.com'>maps.goo..</a>"
      assert AutoLinker.link(text, phone: true, rel: false, new_window: false, class: false, truncate: 10) == expected
    end

    test "phone and truncate 2" do
      text = "1-555-555-5555 and maps.google.com"
      expected = "<a href=\"#\" class=\"phone-number\" data-phone=\"15555555555\">1-555-555-5555</a> and <a href='http://maps.google.com'>maps.google.com</a>"
      assert AutoLinker.link(text, phone: true, rel: false, new_window: false, class: false, truncate: 2) == expected
    end
  end

  test "skips nested phone" do
    text = "<div class='x555'>test</div>"
    assert AutoLinker.link(text, phone: true, rel: false, new_window: false, class: false) == text
  end

  test "skips nested link" do
    text = "<div class='google.com'>test</div>"
    assert AutoLinker.link(text, phone: true, rel: false, new_window: false, class: false) == text
  end

  test "skips phone number in div" do
    text = "<div> x555 </div>"
    assert AutoLinker.link(text, phone: true, rel: false, new_window: false, class: false) == text
  end

  test "skips link number in div" do
    text = "<div> google.com </div>"
    assert AutoLinker.link(text, phone: true, rel: false, new_window: false, class: false) == text
  end

  test "does not skip phone number after div" do
    text = "<div> x555 </div> x555"
    expected = "<div> x555 </div> <a href=\"#\" class=\"phone-number\" data-phone=\"555\">x555</a>"
    assert AutoLinker.link(text, phone: true, rel: false, new_window: false, class: false) == expected
  end

  test "skips links in nested tags" do
    # text = "<div> <b>test</b> google.com x555</div>"
    text = "<a> <b>test</b> google.com </a>"
    assert AutoLinker.link(text, phone: true, rel: false, new_window: false, class: false) == text
  end

  test "url false" do
    text = "test google.com"
    assert AutoLinker.link(text, phone: true, url: false) == text
    assert AutoLinker.link(text, phone: false, url: false) == text
  end
end
