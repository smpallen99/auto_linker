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

  defp build_attrs(attrs, _, opts, :rel) do
    if rel = Map.get(opts, :rel, "noopener noreferrer"),
      do: [{:rel, rel} | attrs], else: attrs
  end
  defp build_attrs(attrs, _, opts, :target) do
    if Map.get(opts, :new_window, true),
      do: [{:target, :_blank} | attrs], else: attrs
  end
  defp build_attrs(attrs, _, opts, :class) do
    if cls = Map.get(opts, :class, "auto-linker"),
      do: [{:class, cls} | attrs], else: attrs
  end
  defp build_attrs(attrs, url, _opts, :scheme) do
    if String.starts_with?(url, ["http://", "https://"]),
      do: [{:href, url} | attrs], else: [{:href, "http://" <> url} | attrs]
  end

  defp format_url(attrs, url, opts) do
    url =
      url
      |> strip_prefix(Map.get(opts, :strip_prefix, true))
      |> truncate(Map.get(opts, :truncate, false))
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

  def create_phone_link([], buffer, _) do
    buffer
  end
  def create_phone_link([h | t], buffer, opts) do
    create_phone_link t, format_phone_link(h, buffer, opts), opts
  end

  def format_phone_link([h | _], buffer, opts) do
    val =
      h
      |> String.replace(~r/[\.\+\- x\(\)]+/, "")
      |> format_phone_link(h, opts)
    # val = ~s'<a href="#" class="phone-number" data-phone="#{number}">#{h}</a>'
    String.replace(buffer, h, val)
  end

  def format_phone_link(number, original, opts) do
    tag = opts[:tag] || "a"
    class = opts[:class] || "phone-number"
    data_phone = opts[:data_phone] || "data-phone"
    attrs = format_attributes(opts[:attributes] || [])
    href = opts[:href] || "#"

    ~s'<#{tag} href="#{href}" class="#{class}" #{data_phone}="#{number}"#{attrs}>#{original}</#{tag}>'
  end

  defp format_attributes(attrs) do
    Enum.reduce(attrs, "", fn {name, value}, acc ->
      acc <> ~s' #{name}="#{value}"'
    end)
  end
end
