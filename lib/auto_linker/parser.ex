defmodule AutoLinker.Parser do
  @moduledoc """
  Module to handle parsing the the input string.
  """

  alias AutoLinker.Builder

  @doc """
  Parse the given string.

  Parses the string, replacing the matching urls with an html link.

  ## Examples

      iex> AutoLinker.Parser.parse("Check out google.com")
      "Check out <a href='http://google.com' class='auto-linker' target='_blank' rel='noopener noreferrer'>google.com</a>"
  """

  def parse(text, opts \\ %{})
  def parse(text, list) when is_list(list), do: parse(text, Enum.into(list, %{}))

  def parse(text, opts) do
    if (exclude = Map.get(opts, :exclude_pattern, false)) && String.starts_with?(text, exclude) do
      text
    else
      parse(text, Map.get(opts, :scheme, false), opts, {"", "", :parsing})
    end
  end


  # state = {buffer, acc, state}

  defp parse("", _scheme, _opts ,{"", acc, _}),
    do: acc

  defp parse("", scheme, opts ,{buffer, acc, _}),
    do: acc <> check_and_link(buffer, scheme, opts)
  defp parse("<" <> text, scheme, opts, {"", acc, :parsing}),
    do: parse(text, scheme, opts, {"<", acc, {:open, 1}})

  defp parse(">" <> text, scheme, opts, {buffer, acc, {:attrs, level}}),
    do: parse(text, scheme, opts, {"", acc <> buffer <> ">", {:html, level}})

  defp parse(<<ch::8>> <> text, scheme, opts, {"", acc, {:attrs, level}}),
    do: parse(text, scheme, opts, {"", acc <> <<ch::8>>, {:attrs, level}})

  defp parse("</" <> text, scheme, opts, {buffer, acc, {:html, level}}),
    do: parse(text, scheme, opts,
      {"", acc <> check_and_link(buffer, scheme, opts) <> "</", {:close, level}})

  defp parse(">" <> text, scheme, opts, {buffer, acc, {:close, 1}}),
    do: parse(text, scheme, opts, {"", acc <> buffer <> ">", :parsing})

  defp parse(">" <> text, scheme, opts, {buffer, acc, {:close, level}}),
    do: parse(text, scheme, opts, {"", acc <> buffer <> ">", {:html, level - 1}})

  defp parse(" " <> text, scheme, opts, {buffer, acc, {:open, level}}),
    do: parse(text, scheme, opts, {"", acc <> buffer <> " ", {:attrs, level}})
  defp parse("\n" <> text, scheme, opts, {buffer, acc, {:open, level}}),
    do: parse(text, scheme, opts, {"", acc <> buffer <> "\n", {:attrs, level}})

  # default cases where state is not important
  defp parse(" " <> text, scheme, opts, {buffer, acc, state}),
    do: parse(text, scheme, opts,
      {"", acc <> check_and_link(buffer, scheme, opts) <> " ", state})
  defp parse("\n" <> text, scheme, opts, {buffer, acc, state}),
    do: parse(text, scheme, opts,
      {"", acc <> check_and_link(buffer, scheme, opts) <> "\n", state})

  defp parse(<<ch::8>> <> text, scheme, opts, {buffer, acc, state}),
    do: parse(text, scheme, opts, {buffer <> <<ch::8>>, acc, state})


  defp check_and_link(buffer, scheme, opts) do
    buffer
    |> is_url?(scheme)
    |> link_url(buffer, opts)
  end

  @doc false
  def is_url?(buffer, true) do
    re = ~r{^(?:http(s)?:\/\/)?[\w.-]+(?:\.[\w\.-]+)+[\w\-\._~:/?#[\]@!\$&'\(\)\*\+,;=.]+$}
    Regex.match? re, buffer
  end
  def is_url?(buffer, _) do
    re = ~r{^[\w.-]+(?:\.[\w\.-]+)+[\w\-\._~:/?#[\]@!\$&'\(\)\*\+,;=.]+$}
    Regex.match? re, buffer
  end

  @doc false
  def link_url(true, buffer, opts) do
    Builder.create_link(buffer, opts)
  end
  def link_url(_, buffer, _opts), do: buffer

end
