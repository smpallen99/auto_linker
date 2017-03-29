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

  import AutoLinker.Parser

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


end
