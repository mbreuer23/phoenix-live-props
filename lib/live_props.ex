defmodule LiveProps do
  @moduledoc ~S'''
  LiveProps is a library for managing properties and state within Phoenix LiveViews
  and Phoenix LiveComponents.

  ### Features

    * Declaratively define props and state, initialize default values, and compute derived values
    using the `LiveProps.Prop.prop/3` and `LiveProps.Prop.state/3` macros.

    * Supports required props

    * Supports automatic re-computation of computed props and state

    * Props automatically added to module documentation.

  ### Example

  Inside a LiveView or LiveComponent, you must use `LiveProps.LiveView` or `LiveProps.LiveComponent`,
  respectively.  LiveComponents can have state and props, while a LiveView can only have state,
  so we'll look at an example LiveComponent to demonstrate both.

  Here's a simple Button component that just has props:

      defmodule ButtonComponent do
        use Phoenix.LiveComponent
        use LiveProps.LiveComponent

        prop :class, :string, default: "button"
        prop :text, :string, default: "Click me"
        prop :on_click, :string, default: "click_button"

        def render(assigns) do
          ~L"""
          <button class="<%= @class %>"
                  phx-click="<%= @on_click %>">
            <%= @text %>
          </button>
          """
        end

  In this example we define three props that will be automatically assigned default values, so
  you don't have to define your own mount or update callbacks to do it yourself.

      defmodule MyAppWeb.ThermostatComponent do
        # If you generated an app with mix phx.new --live,
        # the line below would be: use MyAppWeb, :live_component
        use Phoenix.LiveComponent
        use LiveProps.LiveComponent

        prop :user_id, :integer, required: true
        prop :temperature, :float, compute: :get_temperature

        state :mode, :atom, default: :verbose

        def render(assigns) do
          ~L"""
          <%= case @mode  do %>
            <% :verbose -> %>
              Current temperature: <%= @temperature %>

            <% _ -> %>
              <%= @temperature %>
          <% end %>
          <button phx-click="toggle-mode" phx-target="<%= @myself %>">Toggle mode</button>
          """
        end

        def get_temperature(%{assigns: assigns} = _socket) do
          Thermostat.get_user_reading(assigns.user_id)
        end

        def handle_event("toggle-mode", _, %{assigns: assigns} = socket) do
          new_mode = if assigns.mode == :verbose, do: :compact, else: :verbose

          {:noreply, set_state(socket, :mode, new_mode)}
        end
      end

  Our component requires a `:user_id` prop, which it uses to fetch the temperature.
  Since it is required, an error will be raised if you forget to pass it in.

  We also have the `:temperature` prop, which is a computed prop.  This will be re-calculated
  automatically anytime the :user_id prop changes.  It is calculated by `get_temperature/1` which
  takes the socket assigns as an argument and returns the value to be assigned.  Calculations are run
  in the order defined so we could add even more computed props which depend on the temperature assign.

  Lastly, the component has a state called `:mode` which controls the display.  We've given
  it a default value, which is assigned on mount behind the scenes.  We could also add computed states
  that depend on other states.  In the "toggle_mode" handler we use `LiveProps.States.set_state/3` to
  update the `:mode`.  We could have just done a regular `Phoenix.LiveView.assign/3` call but
  using `set_state/3` is useful when we want to trigger the re-calculation of other states
  as well (in this case, there are none).

  Notice what our component does not have: a `c:Phoenix.LiveComponent.mount/1`, `c:Phoenix.LiveComponent.update/2`
  or `c:Phoenix.LiveComponent.preload/1` callback.  LiveProps handles that for you, by injecting lightweight callbacks
  behind the scenes.

  You can still define your own callbacks if you need to, and everything should continue to work.
  In a LiveComponent, any callbacks
  you define will be run **after** the the LiveProps callbacks (i.e. defaults and computed values
  will already be assigned to the socket).  The `LiveProps.LiveComponent` documentation
  has additional information on component lifecycles.

  This module is not intended to be used directly but rather by means of
  `LiveProps.LiveView` and `LiveProps.LiveComponent`.  Please see docs for those
  modules for additional information.
  '''

  defmacro __using__(include: include) do
    attribute_names = for func <- include, into: [], do: prefix(func)

    postlude =
      quote do
        @before_compile unquote(__MODULE__)

        for func <- unquote(attribute_names) do
          Module.register_attribute(__MODULE__, func, accumulate: true)
        end
      end

    [
      maybe_import_props(include),
      maybe_import_states(include),
      postlude
    ]
  end

  defp maybe_import_props(include) do
    if :prop in include do
      quote do
        import LiveProps.Props
      end
    end
  end

  defp maybe_import_states(include) do
    if :state in include do
      quote do
        import LiveProps.States
      end
    end
  end

  defmacro __before_compile__(env) do
    LiveProps.Docs.generate_docs(env)

    [
      quoted_prop_api(env),
      quoted_state_api(env)
    ]
  end

  def __prop__(name, type, opts, module) do
    define(:prop, name, type, opts, module)
  end

  # def __put_props__(assigns, kinds, module) when is_list(kinds) do
  #   for kind <- kinds, reduce: assigns do
  #     assigns ->
  #       __put_props__(assigns, kind, module)
  #   end
  # end

  def __put_props__(assigns, kind, module) do
    for prop <- module.__props__(kind), reduce: assigns do
      assigns ->
        put_value(assigns, prop, kind)
    end
  end

  def __assign_props__(socket, kind, module) do
    for prop <- module.__props__(kind), reduce: socket do
      socket ->
        assign_value(socket, prop, kind)
    end
  end

  def __state__(name, type, opts, module) do
    define(:state, name, type, opts, module)
  end

  def __set_state__!(socket, assigns, module) do
    assigns = Enum.into(assigns, %{})
    supplied_states = Map.keys(assigns)
    valid_states = for s <- module.__states__(:all), do: s.name

    case supplied_states -- valid_states do
      [] ->
        __set_state__(socket, assigns, module)

      keys ->
        raise ArgumentError, """
        The following keys are not valid states for #{inspect(module)}.

        #{inspect(keys)}

        The following states are defined:

        #{inspect(valid_states)}
        """
    end
  end

  def __set_state__(socket, assigns, module) do
    assigns = Enum.into(assigns, %{})

    valid_states = for s <- module.__states__(:all), do: s.name

    for {k, v} <- assigns, k in valid_states, reduce: socket do
      socket ->
        Phoenix.LiveView.assign(socket, k, v)
    end
    |> __assign_states__(:computed, module)
    |> __assign_states__(:async, module)
  end

  def __put_states__(assigns, kind, module) do
    for state <- module.__states__(kind), reduce: assigns do
      assigns ->
        put_value(assigns, state, kind)
    end
  end

  def __assign_states__(socket, kind, module) do
    for state <- module.__states__(kind), reduce: socket do
      socket ->
        assign_value(socket, state, kind)
    end
  end

  defp get_value(:defaults, attribute, _assigns), do: attribute[:default]
  defp get_value(kind, attribute, assigns) when kind in [:computed, :async] do
    attribute[:compute].(assigns)
  end

  defp put_value(map, attribute, :computed) do
    Map.put(map, attribute.name, get_value(:computed, attribute, map))
  end

  defp put_value(map, attribute, :defaults) do
    Map.put_new(map, attribute.name, get_value(:defaults, attribute, map))
  end

  defp assign_value(socket, attribute, kind) when kind in [:computed, :async] do
    Phoenix.LiveView.assign(socket, attribute.name, get_value(kind, attribute, socket.assigns))
  end

  defp assign_value(socket, attribute, :defaults) do
    Phoenix.LiveView.assign_new(socket, attribute.name, fn -> get_value(:defaults, attribute, socket.assigns) end)
  end

  defp define(attribute, name, type, opts, module) do
    already_defined_names =
      Module.get_attribute(module, prefix(attribute))
      |> Enum.map(& &1.name)

    if name in already_defined_names do
      raise ArgumentError, "#{attribute} with name \"#{name}\" defined more than once."
    end

    put_attribute!(attribute, name, type, opts, module)
  end

  defp put_attribute!(attribute, name, type, opts, module) do
    definition = LiveProps.Factory.build_attribute!(attribute, name, type, opts, module)
    Module.put_attribute(module, prefix(attribute), definition)
  end

  defp quoted_prop_api(env) do
    props = Module.get_attribute(env.module, prefix(:prop), []) |> Enum.reverse()
    default_props = for p <- props, p[:has_default] == true, do: p
    computed_props = for p <- props, p[:is_computed] == true, do: p
    required_props = for p <- props, p[:required] == true, do: p

    quote do
      def __props__(:all), do: unquote(Macro.escape(props))
      def __props__(:defaults), do: unquote(Macro.escape(default_props))
      def __props__(:computed), do: unquote(Macro.escape(computed_props))
      def __props__(:required), do: unquote(Macro.escape(required_props))
    end
  end

  defp quoted_state_api(env) do
    states = Module.get_attribute(env.module, prefix(:state), []) |> Enum.reverse()
    default_states = for s <- states, s[:has_default] == true, do: s
    computed_states = for s <- states, s[:is_computed] == true && s[:after_connect] != true, do: s
    async_states = for s <- states, s[:is_computed] == true && s[:after_connect] == true, do: s

    quote do
      def __states__(:all), do: unquote(Macro.escape(states))
      def __states__(:defaults), do: unquote(Macro.escape(default_states))
      def __states__(:computed), do: unquote(Macro.escape(computed_states))
      def __states__(:async), do: unquote(Macro.escape(async_states))
    end
  end

  @doc false
  def prefix(atom) when is_atom(atom) do
    ("liveprop_" <> Atom.to_string(atom))
    |> String.to_atom()
  end
end
