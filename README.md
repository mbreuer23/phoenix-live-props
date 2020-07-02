# LiveProps

Add props and states to Phoenix LiveViews and LiveComponents

## Example

```elixir
defmodule ButtonComponent do
  use Phoenix.LiveComponent
  use LiveProps.LiveComponent

  # define props andd have their defaults
  # assigned automatically
  prop :class, :string, default: "button"
  prop :text, :string, default: "Click me"
  prop :on_click, :string, default: "click_button"

  # define a required prop
  prop :required_prop, :any, required: true

  def render(assigns) do
    ~L"""
    <button class="<%= @button %>"
            phx-click="<%= @on_click %>">
      <%= @text %>
    </button>
    """
  end
```
In this example we three props that will be given automatically given default values, so
you don't have to define your own mount or update callbacks to do it yourself.

Also, if we forget to pass in the required prop,
the component will raise.

More examples can be found in the LiveProps [documentation]((https://hexdocs.pm/live_props)).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `live_props` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:live_props, "~> 0.2.1"}
  ]
end
```

## Documentation

The docs can
be found at [https://hexdocs.pm/live_props](https://hexdocs.pm/live_props).

