# AutoLinker

[![Build Status](https://travis-ci.org/smpallen99/auto_linker.png?branch=master)](https://travis-ci.org/smpallen99/auto_linker) [![Hex Version][hex-img]][hex] [![License][license-img]][license]

[hex-img]: https://img.shields.io/hexpm/v/auto_linker.svg
[hex]: https://hex.pm/packages/auto_linker
[license-img]: http://img.shields.io/badge/license-MIT-brightgreen.svg
[license]: http://opensource.org/licenses/MIT

AutoLinker is a basic package for turning website names into links.

Use this package in your web view to convert web references into click-able links.

This is a very early version. Some of the described options are not yet functional.

## Installation

The package can be installed by adding `auto_linker` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:auto_linker, "~> 0.1"}]
end
```

## Usage

```
iex> AutoLinker.link("google.com")
"<a href='http://google.com' class='auto-linker' target='_blank' rel='noopener noreferrer'>google.com</a>"

iex> AutoLinker.link("google.com", new_window: false, rel: false)
"<a href='http://google.com' class='auto-linker'>google.com</a>"

iex> AutoLinker.link("google.com", new_window: false, rel: false, class: false)
"<a href='http://google.com'>google.com</a>"
```

See the [Docs](https://hexdocs.pm/auto_linker/) for more examples

## License

`auto_linker` is Copyright (c) 2017 E-MetroTel

The source is released under the MIT License.

Check [LICENSE](LICENSE) for more information.
