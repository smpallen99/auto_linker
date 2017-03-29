defmodule AutoLinker do
  @moduledoc """
  Create url links from text containing urls.

  Turns an input string like `"Check out google.com"` into
  `Check out `"<a href='http://google.com' target='_blank' rel='noopener noreferrer'>google.com</a>"`

  ## Examples

      iex> AutoLinker.link("google.com")
      "<a href='http://google.com' class='auto-linker' target='_blank' rel='noopener noreferrer'>google.com</a>"

      iex> AutoLinker.link("google.com", new_window: false, rel: false)
      "<a href='http://google.com' class='auto-linker'>google.com</a>"

      iex> AutoLinker.link("google.com", new_window: false, rel: false, class: false)
      "<a href='http://google.com'>google.com</a>"
  """

  @doc """
  Auto link a string.
  """
  def link(text, opts \\ []) do
    opts =
      :auto_linker
      |> Application.get_all_env()
      |> Keyword.merge(opts)

    parse text, opts
  end

  # state = {buffer, acc, state}
  defp parse(text, opts) do
    parse(text, Keyword.get(opts, :scheme, false), opts, {"", "", false})
  end

  defp parse("", _scheme, _opts ,{_, acc, _}), do: acc

  defp parse(text, scheme, opts, {buffer, acc, state}) do
    acc = acc <> create_link(text, opts)
    parse("", scheme, opts, {buffer, acc, state})
  end

  defp create_link(url, opts) do
    []
    |> build_attrs(url, opts, :rel)
    |> build_attrs(url, opts, :target)
    |> build_attrs(url, opts, :class)
    |> build_attrs(url, opts, :scheme)
    |> format_url(url, opts)
  end

  defp build_attrs(attrs, _, opts, :rel) do
    if rel = Keyword.get(opts, :rel, "noopener noreferrer"),
      do: [{:rel, rel} | attrs], else: attrs
  end
  defp build_attrs(attrs, _, opts, :target) do
    if Keyword.get(opts, :new_window, true),
      do: [{:target, :_blank} | attrs], else: attrs
  end
  defp build_attrs(attrs, _, opts, :class) do
    if cls = Keyword.get(opts, :class, "auto-linker"),
      do: [{:class, cls} | attrs], else: attrs
  end
  defp build_attrs(attrs, url, _opts, :scheme) do
    if String.starts_with?(url, ["http://", "https://"]),
      do: [{:href, url} | attrs], else: [{:href, "http://" <> url} | attrs]
  end

  defp format_url(attrs, url, opts) do
    url =
      url
      |> strip_prefix(Keyword.get(opts, :strip_prefix, true))
      |> truncate(Keyword.get(opts, :truncate, false))
    attrs =
      attrs
      |> Enum.map(fn {key, value} -> ~s(#{key}='#{value}') end)
      |> Enum.join(" ")
    "<a #{attrs}>" <> url <> "</a>"
  end

  defp truncate(url, false), do: url
  defp truncate(url, len) when len < 3, do: url
  defp truncate(url, len) do
    if String.length(url) > len, do: String.slice(url, 0, len - 2) <> "..", else: url
  end

  defp strip_prefix(url, true) do
    url
    |> String.replace(~r/^https?:\/\//, "")
    |> String.replace(~r/^www\./, "")
  end
  defp strip_prefix(url, _), do: url
end
