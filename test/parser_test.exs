defmodule AutoLinker.ParserTest do
  use ExUnit.Case
  doctest AutoLinker.Parser

  import AutoLinker.Parser


  describe "is_url" do
    test "valid scheme true" do
      valid_scheme_urls()
      |> Enum.each(fn url ->
        assert is_url?(url, true)
      end)
    end
    test "invalid scheme true" do
      invalid_scheme_urls()
      |> Enum.each(fn url ->
        refute is_url?(url, true)
      end)
    end
    test "valid scheme false" do
      valid_non_scheme_urls()
      |> Enum.each(fn url ->
        assert is_url?(url, false)
      end)
    end
    test "invalid scheme false" do
      invalid_non_scheme_urls()
      |> Enum.each(fn url ->
        refute is_url?(url, false)
      end)
    end
  end

  describe "parse" do
    test "does not link attributes" do
      text = "Check out <a href='google.com'>google</a>"
      assert parse(text) == text
      text = "Check out <img src='google.com' alt='google.com'/>"
      assert parse(text) == text
      text = "Check out <span><img src='google.com' alt='google.com'/></span>"
      assert parse(text) == text
    end

    test "links url inside html" do
      text = "Check out <div class='section'>google.com</div>"
      expected = "Check out <div class='section'><a href='http://google.com'>google.com</a></div>"
      assert parse(text, class: false, rel: false, new_window: false) ==  expected
    end

    test "excludes html with specified class" do
      text = "```Check out <div class='section'>google.com</div>```"
      assert parse(text, exclude_pattern: "```") == text
    end
  end

  def valid_scheme_urls, do: [
    "https://www.example.com",
    "http://www2.example.com",
    "http://home.example-site.com",
    "http://blog.example.com",
    "http://www.example.com/product",
    "http://www.example.com/products?id=1&page=2",
    "http://www.example.com#up",
    "http://255.255.255.255",
    "http://www.site.com:8008"
  ]

  def invalid_scheme_urls, do: [
    "http://invalid.com/perl.cgi?key= | http://web-site.com/cgi-bin/perl.cgi?key1=value1&key2",
  ]

  def valid_non_scheme_urls, do: [
    "www.example.com",
    "www2.example.com",
    "www.example.com:2000",
    "www.example.com?abc=1",
    "example.example-site.com",
    "example.com",
    "example.ca",
    "example.tv",
    "example.com:999?one=one",
    "255.255.255.255",
    "255.255.255.255:3000?one=1&two=2",
  ]

  def invalid_non_scheme_urls, do: [
    "invalid.com/perl.cgi?key= | web-site.com/cgi-bin/perl.cgi?key1=value1&key2",
    "invalid.",
    "hi..there"
  ]

end
