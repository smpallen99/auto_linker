defmodule AutoLinker.Parser do
  @moduledoc """
  Module to handle parsing the the input string.
  """

  alias AutoLinker.Builder

  @doc """
  Parse the given string, identifying items to link.

  Parses the string, replacing the matching urls and phone numbers with an html link.

  ## Examples

      iex> AutoLinker.Parser.parse("Check out google.com")
      "Check out <a href='http://google.com' class='auto-linker' target='_blank' rel='noopener noreferrer'>google.com</a>"

      iex> AutoLinker.Parser.parse("call me at x9999", phone: true)
      ~s{call me at <a href="#" class="phone-number" data-phone="9999">x9999</a>}

      iex> AutoLinker.Parser.parse("or at home on 555.555.5555", phone: true)
      ~s{or at home on <a href="#" class="phone-number" data-phone="5555555555">555.555.5555</a>}

      iex> AutoLinker.Parser.parse(", work (555) 555-5555", phone: true)
      ~s{, work <a href="#" class="phone-number" data-phone="5555555555">(555) 555-5555</a>}
  """

  @hash_re ~S"(#[^\s\?&=]*)?"
  @ip_re ~S"([0-9]{1,3}(?:\.[0-9]{1,3}){3}))"
  @query_re ~S"(\?[^\s=&\?]+=[^\s&=\?]+(?:&[^\s=&\?]+=[^\s=&\?]+)*)?$"
  @routes_re ~S"(\/[^\s\?=&]+)*"
  @port_re ~S/(:[0-9]{1,5})?/
  @url_re ~S"(([\w\-]+(?:\.[\w\-]+)*\.[A-Za-z]{2,6})|" <> @ip_re <> @hash_re
  @match_re @url_re <> @port_re <> @routes_re <> ~S"\/?" <> @query_re

  @match_url Regex.compile!("^" <> @match_re)
  @match_scheme Regex.compile!(~S"^(?:http(s)?:\/\/)?" <> @match_re)

  @match_phone ~r"((?:x\d{2,7})|(?:(?:\d{1,3}[\s\-.]?)?(?:\+?1\s?(?:[.-]\s?)?)?(?:\(\s?(?:[2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9])\s?\)|(?:[2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9]))\s?(?:[.-]\s?)?)(?:[2-9]1[02-9]|[2-9][02-9]1|[2-9][02-9]{2})\s?(?:[.-]\s?)?(?:[0-9]{4}))"

  def match_url, do: @match_url
  def match_scheme, do: @match_scheme

  def parse(text, opts \\ %{})
  def parse(text, list) when is_list(list), do: parse(text, Enum.into(list, %{}))

  def parse(text, opts) do
    options = parse_options(opts)

    text
    |> split_code_blocks()
    |> Enum.reduce([], fn
      {:skip, block}, acc ->
        [block | acc]

      block, acc ->
        [do_parse(block, options) | acc]
    end)
    |> Enum.join("")
  end

  defp do_parse(text, %{phone: false} = opts), do: do_parse(text, Map.delete(opts, :phone))
  defp do_parse(text, %{url: false} = opts), do: do_parse(text, Map.delete(opts, :url))

  defp do_parse(text, %{phone: _} = opts) do
    text
    |> do_parse(false, opts, {"", "", :parsing}, &check_and_link_phone/3)
    |> do_parse(Map.delete(opts, :phone))
  end

  defp do_parse(text, %{markdown: true} = opts) do
    text
    |> Builder.create_markdown_links(opts)
    |> do_parse(Map.delete(opts, :markdown))
  end

  defp do_parse(text, %{url: _} = opts) do
    if (exclude = Map.get(opts, :exclude_pattern, false)) && String.starts_with?(text, exclude) do
      text
    else
      do_parse(text, Map.get(opts, :scheme, false), opts, {"", "", :parsing}, &check_and_link/3)
    end
    |> do_parse(Map.delete(opts, :url))
  end

  defp do_parse(text, _), do: text

  defp do_parse("", _scheme, _opts, {"", acc, _}, _handler),
    do: acc

  defp do_parse("", scheme, opts, {buffer, acc, _}, handler),
    do: acc <> handler.(buffer, scheme, opts)

  defp do_parse("<a" <> text, scheme, opts, {buffer, acc, :parsing}, handler),
    do: do_parse(text, scheme, opts, {"", acc <> buffer <> "<a", :skip}, handler)

  defp do_parse("</a>" <> text, scheme, opts, {buffer, acc, :skip}, handler),
    do: do_parse(text, scheme, opts, {"", acc <> buffer <> "</a>", :parsing}, handler)

  defp do_parse("<" <> text, scheme, opts, {"", acc, :parsing}, handler),
    do: do_parse(text, scheme, opts, {"<", acc, {:open, 1}}, handler)

  defp do_parse(">" <> text, scheme, opts, {buffer, acc, {:attrs, level}}, handler),
    do: do_parse(text, scheme, opts, {"", acc <> buffer <> ">", {:html, level}}, handler)

  defp do_parse(<<ch::8>> <> text, scheme, opts, {"", acc, {:attrs, level}}, handler),
    do: do_parse(text, scheme, opts, {"", acc <> <<ch::8>>, {:attrs, level}}, handler)

  defp do_parse("</" <> text, scheme, opts, {buffer, acc, {:html, level}}, handler),
    do:
      do_parse(
        text,
        scheme,
        opts,
        {"", acc <> handler.(buffer, scheme, opts) <> "</", {:close, level}},
        handler
      )

  defp do_parse(">" <> text, scheme, opts, {buffer, acc, {:close, 1}}, handler),
    do: do_parse(text, scheme, opts, {"", acc <> buffer <> ">", :parsing}, handler)

  defp do_parse(">" <> text, scheme, opts, {buffer, acc, {:close, level}}, handler),
    do: do_parse(text, scheme, opts, {"", acc <> buffer <> ">", {:html, level - 1}}, handler)

  defp do_parse(" " <> text, scheme, opts, {buffer, acc, {:open, level}}, handler),
    do: do_parse(text, scheme, opts, {"", acc <> buffer <> " ", {:attrs, level}}, handler)

  defp do_parse("\n" <> text, scheme, opts, {buffer, acc, {:open, level}}, handler),
    do: do_parse(text, scheme, opts, {"", acc <> buffer <> "\n", {:attrs, level}}, handler)

  # default cases where state is not important
  defp do_parse(" " <> text, scheme, %{phone: _} = opts, {buffer, acc, state}, handler),
    do: do_parse(text, scheme, opts, {buffer <> " ", acc, state}, handler)

  defp do_parse(" " <> text, scheme, opts, {buffer, acc, state}, handler),
    do:
      do_parse(
        text,
        scheme,
        opts,
        {"", acc <> handler.(buffer, scheme, opts) <> " ", state},
        handler
      )

  defp do_parse("\n" <> text, scheme, opts, {buffer, acc, state}, handler),
    do:
      do_parse(
        text,
        scheme,
        opts,
        {"", acc <> handler.(buffer, scheme, opts) <> "\n", state},
        handler
      )

  defp do_parse(<<ch::8>>, scheme, opts, {buffer, acc, state}, handler),
    do:
      do_parse(
        "",
        scheme,
        opts,
        {"", acc <> handler.(buffer <> <<ch::8>>, scheme, opts), state},
        handler
      )

  defp do_parse(<<ch::8>> <> text, scheme, opts, {buffer, acc, state}, handler),
    do: do_parse(text, scheme, opts, {buffer <> <<ch::8>>, acc, state}, handler)

  def check_and_link(buffer, scheme, opts) do
    buffer
    |> is_url?(scheme, opts)
    |> link_url(buffer, opts)
  end

  def check_and_link_phone(buffer, _, opts) do
    buffer
    |> match_phone
    |> link_phone(buffer, opts)
  end

  @doc false
  def is_url?(buffer, true), do: Regex.match?(match_scheme_re(), buffer)
  def is_url?(buffer, _), do: Regex.match?(match_url_re(), buffer)

  @doc false
  def is_url?(buffer, true, %{match_scheme_re: re}), do: Regex.match?(re, buffer)
  def is_url?(buffer, _, %{match_url_re: re}), do: Regex.match?(re, buffer)
  def is_url?(buffer, scheme, _), do: is_url?(buffer, scheme)

  @doc false
  def match_phone(buffer) do
    case Regex.scan(match_phone_re(), buffer) do
      [] -> nil
      other -> other
    end
  end

  defp match_scheme_re do
    :auto_linker
    |> Application.get_env(:match_scheme_re, @match_scheme)
    |> compile_re()
  end

  defp match_url_re do
    :auto_linker
    |> Application.get_env(:match_url_re, @match_url)
    |> compile_re()
  end

  defp match_phone_re do
    :auto_linker
    |> Application.get_env(:match_phone_re, @match_phone)
    |> compile_re()
  end

  defp compile_re(string) when is_binary(string), do: Regex.compile!(string)
  defp compile_re(re), do: re

  def link_phone(nil, buffer, _), do: buffer

  def link_phone(list, buffer, opts) do
    Builder.create_phone_link(list, buffer, opts)
  end

  @doc false
  def link_url(true, buffer, opts) do
    Builder.create_link(buffer, opts)
  end

  def link_url(_, buffer, _opts), do: buffer

  def split_code_blocks(text) do
    if text =~ "!md" && text =~ "```" do
      split_code_blocks(text, [""], false)
    else
      [text]
    end
  end

  defp split_code_blocks("", acc, false) do
    acc
  end

  defp split_code_blocks("", [buff | acc], true) do
    [{:skip, buff} | acc]
  end

  defp split_code_blocks("```" <> rest, [buff | acc], true) do
    split_code_blocks(rest, ["", {:skip, buff <> "```"} | acc], false)
  end

  defp split_code_blocks("```" <> rest, acc, false) do
    split_code_blocks(rest, ["```" | acc], true)
  end

  defp split_code_blocks(<<ch::8>> <> rest, [buff | acc], in_block) do
    split_code_blocks(rest, [buff <> <<ch::8>> | acc], in_block)
  end

  defp parse_options(opts) do
    Map.merge(
      %{
        match_scheme_re: match_scheme_re(),
        match_url_re: match_url_re(),
        match_phone_re: match_phone_re()
      },
      Map.merge(default_options(), opts)
    )
  end

  defp default_options do
    :auto_linker
    |> Application.get_env(:opts, [])
    |> Enum.into(%{})
    |> Map.put_new(:url, true)
    |> Map.put(
      :attributes,
      Application.get_env(:auto_linker, :attributes, [])
    )
  end
end
