defmodule AutoLinker do
  @moduledoc """
  Create url links from text containing urls.

  Turns an input string like `"Check out google.com"` into
  `Check out "<a href='http://google.com' target='_blank' rel='noopener noreferrer'>google.com</a>"`

  ## Examples

      iex> AutoLinker.link("google.com")
      "<a href='http://google.com' class='auto-linker' target='_blank' rel='noopener noreferrer'>google.com</a>"

      iex> AutoLinker.link("google.com", new_window: false, rel: false)
      "<a href='http://google.com' class='auto-linker'>google.com</a>"

      iex> AutoLinker.link("google.com", new_window: false, rel: false, class: false)
      "<a href='http://google.com'>google.com</a>"

      iex> AutoLinker.link("[Google](http://google.com)", markdown: true, new_window: false, rel: false, class: false)
      "<a href='http://google.com'>Google</a>"

      iex> AutoLinker.link("[Google Search](http://google.com)", markdown: true)
      "<a href='http://google.com' class='auto-linker' target='_blank' rel='noopener noreferrer'>Google Search</a>"

      iex> AutoLinker.link("google.com", truncate: 12)
      "<a href='http://google.com' class='auto-linker' target='_blank' rel='noopener noreferrer'>google.com</a>"

      iex> AutoLinker.link("some-very-long-url.com", truncate: 12)
      "<a href='http://some-very-long-url.com' class='auto-linker' target='_blank' rel='noopener noreferrer'>some-very-..</a>"

      iex> AutoLinker.link("https://google.com", scheme: true)
      "<a href='https://google.com' class='auto-linker' target='_blank' rel='noopener noreferrer'>google.com</a>"

      iex> AutoLinker.link("https://google.com", scheme: true, strip_prefix: false)
      "<a href='https://google.com' class='auto-linker' target='_blank' rel='noopener noreferrer'>https://google.com</a>"
  """

  import AutoLinker.Parser

  @doc """
  Auto link a string.

  Options:

  * `class: "auto-linker"` - specify the class to be added to the generated link. false to clear
  * `rel: "noopener noreferrer"` - override the rel attribute. false to clear
  * `new_window: true` - set to false to remove `target='_blank'` attribute
  * `scheme: false` - Set to true to link urls with schema `http://google`
  * `truncate: false` - Set to a number to truncate urls longer then the number. Truncated urls will end in `..`
  * `strip_prefix: true` - Strip the scheme prefix
  * `exclude_class: false` - Set to a class name when you don't want urls auto linked in the html of the give class
  * `exclude_id: false` - Set to an element id when you don't want urls auto linked in the html of the give element
  * `exclude_patterns: ["```"] - Don't link anything between the the pattern
  * `markdown: false` - link markdown style links

  Each of the above options can be specified when calling `link(text, opts)`
  or can be set in the `:auto_linker's configuration. For example:

       config :auto_linker,
         class: false,
         new_window: false

  Note that passing opts to `link/2` will override the configuration settings.
  """
  def link(text, opts \\ []) do
    parse(text, opts)
  end
end
