defmodule AutoLinker.Builder do
  @moduledoc """
  Module for building the auto generated link.
  """

  @doc """
  Create a link.
  """
  def create_link(url, opts) do
    []
    |> build_attrs(url, opts, :rel)
    |> build_attrs(url, opts, :target)
    |> build_attrs(url, opts, :class)
    |> build_attrs(url, opts, :scheme)
    |> format_url(url, opts)
  end

  def create_markdown_links(text, opts) do
    []
    |> build_attrs(text, opts, :rel)
    |> build_attrs(text, opts, :target)
    |> build_attrs(text, opts, :class)
    |> format_markdown(text, opts)
  end

  defp build_attrs(attrs, _, opts, :rel) do
    if rel = Map.get(opts, :rel, "noopener noreferrer"), do: [{:rel, rel} | attrs], else: attrs
  end

  defp build_attrs(attrs, _, opts, :target) do
    if Map.get(opts, :new_window, true), do: [{:target, :_blank} | attrs], else: attrs
  end

  defp build_attrs(attrs, _, opts, :class) do
    if cls = Map.get(opts, :class, "auto-linker"), do: [{:class, cls} | attrs], else: attrs
  end

  defp build_attrs(attrs, "http://" <> _ = url, _opts, :scheme), do: [{:href, url} | attrs]
  defp build_attrs(attrs, "https://" <> _ = url, _opts, :scheme), do: [{:href, url} | attrs]
  defp build_attrs(attrs, url, _opts, :scheme), do: [{:href, "http://" <> url} | attrs]

  defp format_url(attrs, url, opts) do
    url =
      url
      |> strip_prefix(Map.get(opts, :strip_prefix, true))
      |> truncate(Map.get(opts, :truncate, false))

    attrs = format_attrs(attrs)
    "<a #{attrs}>" <> url <> "</a>"
  end

  defp format_attrs(attrs) do
    attrs
    |> Enum.map(fn {key, value} -> ~s(#{key}='#{value}') end)
    |> Enum.join(" ")
  end

  defp format_markdown(attrs, text, _opts) do
    attrs =
      case format_attrs(attrs) do
        "" -> ""
        attrs -> " " <> attrs
      end

    Regex.replace(~r/\[(.+?)\]\((.+?)\)/, text, "<a href='\\2'#{attrs}>\\1</a>")
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

  def create_phone_link([], buffer, _) do
    buffer
  end

  def create_phone_link(list, buffer, opts) do
    list
    |> Enum.uniq()
    |> do_create_phone_link(buffer, opts)
  end

  def do_create_phone_link([], buffer, _opts) do
    buffer
  end

  def do_create_phone_link([h | t], buffer, opts) do
    do_create_phone_link(t, format_phone_link(h, buffer, opts), opts)
  end

  def format_phone_link([h | _], buffer, opts) do
    val =
      h
      |> String.replace(~r/[\.\+\- x\(\)]+/, "")
      |> format_phone_link(h, opts)

    String.replace(buffer, h, val)
  end

  def format_phone_link(number, original, opts) do
    format_node(
      opts[:tag] || "a",
      [
        format_attr(" href", opts[:href] || "#"),
        format_attr(" class", opts[:class] || "phone-number"),
        format_attr(" " <> (opts[:data_phone] || "data-phone"), number),
        format_attributes(opts[:attributes] || [])
      ],
      original
    )
  end

  defp format_attributes(attrs) do
    Enum.reduce(attrs, "", fn {name, value}, acc ->
      acc <> ~s' #{name}="#{value}"'
    end)
  end

  defp format_attr(name, value), do: [name, ?=, format_quoted(value)]
  defp format_quoted(value), do: [?", value, ?"]

  defp format_node(tag, attrs, contents),
    do: to_string([?<, tag, attrs, ?>, contents, "</", tag, ?>])
end
