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

  # @invalid_url ~r/\.\.+/
  @invalid_url ~r/(\.\.+)|(^(\d+\.){1,2}\d+$)/

  @match_url ~r{^[\w\.-]+(?:\.[\w\.-]+)+[\w\-\._~:/?#[\]@!\$&'\(\)\*\+,;=.]+$}
  @match_scheme ~r{^(?:http(s)?:\/\/)?[\w.-]+(?:\.[\w\.-]+)+[\w\-\._~:/?#[\]@!\$&'\(\)\*\+,;=.]+$}

  @match_phone ~r"((?:x\d{2,7})|(?:(?:\+?1\s?(?:[.-]\s?)?)?(?:\(\s?(?:[2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9])\s?\)|(?:[2-9]1[02-9]|[2-9][02-8]1|[2-9][02-8][02-9]))\s?(?:[.-]\s?)?)(?:[2-9]1[02-9]|[2-9][02-9]1|[2-9][02-9]{2})\s?(?:[.-]\s?)?(?:[0-9]{4}))"

  @default_opts ~w(url)a

  def parse(text, opts \\ %{})
  def parse(text, list) when is_list(list), do: parse(text, Enum.into(list, %{}))

  def parse(text, opts) do
    config =
      :auto_linker
      |> Application.get_env(:opts, [])
      |> Enum.into(%{})
      |> Map.put(:attributes,
        Application.get_env(:auto_linker, :attributes, [])
      )

    opts =
      Enum.reduce @default_opts, opts, fn opt, acc ->
        if is_nil(opts[opt]) and is_nil(config[opt]) do
          Map.put acc, opt, true
        else
          acc
        end
      end

    do_parse text, Map.merge(config, opts)
  end

  defp do_parse(text, %{phone: false} = opts), do: do_parse(text, Map.delete(opts, :phone))
  defp do_parse(text, %{url: false} = opts), do: do_parse(text, Map.delete(opts, :url))

  defp do_parse(text, %{markdown: true} = opts) do
    text
    |> Builder.create_markdown_links(opts)
    |> do_parse(Map.delete(opts, :markdown))
  end
  defp do_parse(text, %{phone: _} = opts) do
    text
    |> do_parse(false, opts, {"", "", :parsing}, &check_and_link_phone/3)
    |> do_parse(Map.delete(opts, :phone))
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

  defp do_parse("", _scheme, _opts ,{"", acc, _}, _handler),
    do: acc

  defp do_parse("", scheme, opts ,{buffer, acc, _}, handler),
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
    do: do_parse(text, scheme, opts,
      {"", acc <> handler.(buffer, scheme, opts) <> "</", {:close, level}}, handler)

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
    do: do_parse(text, scheme, opts,
      {"", acc <> handler.(buffer, scheme, opts) <> " ", state}, handler)

  defp do_parse("\n" <> text, scheme, opts, {buffer, acc, state}, handler),
    do: do_parse(text, scheme, opts,
      {"", acc <> handler.(buffer, scheme, opts) <> "\n", state}, handler)

  defp do_parse(<<ch::8>>, scheme, opts, {buffer, acc, state}, handler),
    do: do_parse("", scheme, opts,
      {"", acc <> handler.(buffer <> <<ch::8>>, scheme, opts), state}, handler)

  defp do_parse(<<ch::8>> <> text, scheme, opts, {buffer, acc, state}, handler),
    do: do_parse(text, scheme, opts, {buffer <> <<ch::8>>, acc, state}, handler)

  def check_and_link(buffer, scheme, opts) do
    buffer
    |> is_url?(scheme)
    |> link_url(buffer, opts)
  end

  def check_and_link_phone(buffer, _, opts) do
    buffer
    |> match_phone
    |> link_phone(buffer, opts)
  end

  @doc false
  def is_url?(buffer, true) do
    if Regex.match? @invalid_url, buffer do
      false
    else
      Regex.match? @match_scheme, buffer
    end
  end

  def is_url?(buffer, _) do
    if Regex.match? @invalid_url, buffer do
      false
    else
      Regex.match? @match_url, buffer
    end
  end

  @doc false
  def match_phone(buffer) do
    case Regex.scan @match_phone, buffer do
      [] -> nil
      other -> other
    end
  end

  def link_phone(nil, buffer, _), do: buffer

  def link_phone(list, buffer, opts) do
    Builder.create_phone_link list, buffer, opts
  end

  @doc false
  def link_url(true, buffer, opts) do
    Builder.create_link(buffer, opts)
  end
  def link_url(_, buffer, _opts), do: buffer

end
