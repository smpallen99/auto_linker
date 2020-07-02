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

  describe "match_phone" do
    test "valid" do
      valid_phone_nunbers()
      |> Enum.each(fn number ->
        assert number |> match_phone() |> valid_number?(number)
      end)
    end

    test "invalid" do
      invalid_phone_numbers()
      |> Enum.each(fn number ->
        assert number |> match_phone() |> is_nil
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
      assert parse(text, class: false, rel: false, new_window: false) == expected
    end

    test "excludes html with specified class" do
      text = "```Check out <div class='section'>google.com</div>```"
      assert parse(text, exclude_pattern: "```") == text
    end
  end

  def valid_number?([list], number) do
    assert List.last(list) == number
  end

  def valid_number?(_, _), do: false

  def valid_scheme_urls,
    do: [
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

  def invalid_scheme_urls,
    do: [
      "http://invalid.com/perl.cgi?key= | http://web-site.com/cgi-bin/perl.cgi?key1=value1&key2"
    ]

  def valid_non_scheme_urls,
    do: [
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
      "255.255.255.255:3000?one=1&two=2"
    ]

  def invalid_non_scheme_urls,
    do: [
      "invalid.com/perl.cgi?key= | web-site.com/cgi-bin/perl.cgi?key1=value1&key2",
      "invalid.",
      "hi..there",
      "555.555.5555"
    ]

  def valid_phone_nunbers,
    do: [
      "x55",
      "x555",
      "x5555",
      "x12345",
      "+1 555 555-5555",
      "555 555-5555",
      "555.555.5555",
      "613-555-5555",
      "1 (555) 555-5555",
      "(555) 555-5555",
      "1.555.555.5555",
      "800 555-5555",
      "1.800.555.5555",
      "1 (800) 555-5555",
      "888 555-5555",
      "887 555-5555",
      "1-877-555-5555",
      "1 800 710-5515"
    ]

  def invalid_phone_numbers,
    do: [
      "5555",
      "x5",
      "(555) 555-55"
    ]
end
