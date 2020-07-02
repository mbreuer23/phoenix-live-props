# Formatting

If you want to prevent the `mix format`
command from inserting parentheses around
your `prop` and `state` definitions, you must edit your .formatter.exs file  to include `:live_props` under the `:import_deps` options.

Your file might look something like this:

```elixir
[
  import_deps: [:ecto, :phoenix, :live_props],
  inputs: ["*.{ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{ex,exs}"],
  subdirectories: ["priv/*/migrations"]
]
```

