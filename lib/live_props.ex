defmodule LiveProps do
  @moduledoc ~S'''
  LiveProps is a library for managing properties and state within Phoenix LiveViews
  and Phoenix LiveComponents.

  ### Features

    * Declaratively define props and state, initialize default values, and compute derived values
    using the `LiveProps.prop/3` and `LiveProps.state/3` macros.

    * Supports required props

    * Supports asynchronous loading of state.

    * Supports automatic re-computation of computed props and state

    * Props automatically added to module documentation.


  ### Example

  Inside a LiveView or LiveComponent, you must use `LiveProps.LiveView` or `LiveProps.LiveComponent`,
  respectively.  LiveComponents can have state and props, while a LiveView can only have state,
  so we'll look at an example LiveComponent to demonstrate both.

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

        def handle_event("toggle-mode", _, socket) do
          new_mode =
            if socket.assigns.mode == :verbose,
              do: :compact,
              else: :verbose

          {:noreply, assign(socket, :mode, new_mode)}
        end
      end

  Our component requires a `:user_id` prop, which it uses to fetch the temperature.
  Since it is required, an error will be raised if you forget to pass it in.

  We also have the `:temperature` prop, which is a computed prop.  This will be re-calculated
  automatically anytime the :user_id prop changes.  It is calculated by `get_temperature/1` which
  takes the socket as an argument and returns the value to be assigned.  Calculations are run
  in the order defined so we could add even more computed props which depend on the temperature assign.

  Lastly, the component has a state called `:mode` which controls the display.  We've given
  it a default value, which is assigned on mount.  We could also add computed states
  which depends on other states.

  Notice what our component does not have: a `c:Phoenix.LiveComponent.mount/1` or `c:Phoenix.LiveComponent.update/2`
  callback.  LiveProps handles that for you, by injecting lightweight mount/1 and update/2 callbacks under the hood.
  In pseudocode, these callbacks look like the following:

      def mount(socket) do
        {:ok, assign_default_states(socket)}
      end

      def update(assigns, socket) do
        raise_if_missing_required_props!(assigns)

        {:ok, assign_props_and_computed_props(socket)}
      end

  While LiveProps defines `mount` and `update` callbacks for you.  You can still define your own
  and everything will continue to work.  In a LiveComponent, any mount or update callbacks
  you define will be run **after** the the LiveProps callbacks (i.e. defaults and computed values
  will already be assigned to the socket)

  This module is not intended to be used directly but rather by means of
  `LiveProps.LiveView` and `LiveProps.LiveComponent`.  Please see docs for those
  modules for additional information.
  '''

  defmacro __using__(include: include) do
    imports = %{
      prop: [{:prop, 2}, {:prop, 3}],
      state: [{:state, 2}, {:state, 3}, {:send_state, 3}, {:set_state, 2}, {:set_state, 3}]
    }

    functions = for func <- include, imp <- imports[func], into: [], do: imp
    attribute_names = for func <- include, into: [], do: prefix(func)

    quote do
      import unquote(__MODULE__), only: unquote(functions)
      @before_compile unquote(__MODULE__)

      for func <- unquote(attribute_names) do
        Module.register_attribute(__MODULE__, func, accumulate: true)
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

  @doc """
  Define a property with the given name and type. Returns `:ok`

  This macro is meant to be called within a LiveComponent only.
  Types can be any atom and are just for documentation purposes.

  ## Options:

    * `:default` - A default value to assign to the prop.
    * `:required` - boolean.  If true, an error will be raised
    if the prop is not passed to the component.
    * `:compute` - 1-arity function that takes the socket as an argument
    and returns the value to be assigned.  Can be an atom of the name
    of a function in your component or a remote function call like `&MyModule.compute/1`
  """
  @spec prop(name :: atom(), type :: atom(), opts :: list()) :: :ok
  defmacro prop(name, type, opts \\ []) do
    quote do
      LiveProps.__prop__(unquote(name), unquote(type), unquote(opts), __MODULE__)
    end
  end

  @doc """
  Define state of given name and type.  Returns :ok.

  Types can be any atom and are just for documentation purposes.


  """
  @spec state(name :: atom(), type :: atom(), opts :: list()) :: :ok
  defmacro state(name, type, opts \\ []) do
    quote do
      LiveProps.__state__(unquote(name), unquote(type), unquote(opts), __MODULE__)
    end
  end

  defmacro set_state(socket, assigns) do
    quote do
      LiveProps.__set_state__(unquote(socket), unquote(assigns), __MODULE__)
    end
  end

  defmacro set_state(socket, key, value) do
    quote do
      LiveProps.__set_state__(unquote(socket), %{unquote(key) => unquote(value)}, __MODULE__)
    end
  end

  def send_state(module, id, assigns) do
    Phoenix.LiveView.send_update(module, [lp_command: :set_state, id: id] ++ assigns)
  end

  def __set_state__(socket, assigns, module) do
    assigns = Enum.into(assigns, %{})

    valid_states = for s <- module.__states__(:all), do: s.name
    supplied_states = Map.keys(assigns)

    case supplied_states -- valid_states do
      [] ->
        :ok

      any ->
        raise RuntimeError, """
          Cannot set state(s) #{inspect(any)} because they have not been defined as states
          in module #{inspect(module)}

          The following states are defined:
          #{inspect(valid_states)}
        """
    end

    socket
    |> Phoenix.LiveView.assign(assigns)
    |> __assign_states__(:computed, module)
    |> __assign_states__(:async, module)
  end

  def __prop__(name, type, opts, module) do
    define(:prop, name, type, opts, module)
  end

  def __state__(name, type, opts, module) do
    define(:state, name, type, opts, module)
  end

  defmacro assign_states(socket, kind) do
    quote bind_quoted: [socket: socket, kind: kind] do
      LiveProps.__assigns_states__(socket, kind, __MODULE__)
    end
  end

  defp get_assigns_value_key(:computed), do: :compute
  defp get_assigns_value_key(:async), do: :compute
  defp get_assigns_value_key(:defaults), do: :default

  defp should_call_functions?(kind) when kind in [:computed, :async], do: true
  defp should_call_functions?(_), do: false

  defp should_force?(:computed), do: true
  defp should_force?(_), do: false

  def __assign_props__(socket, kind, module) do
    value_key = get_assigns_value_key(kind)
    call_functions? = should_call_functions?(kind)
    props = module.__props__(kind)
    force? = should_force?(kind)

    Enum.reduce(props, socket, fn prop, socket ->
      assign(socket, prop, value_key, call_functions?, force?)
    end)
  end

  def __assign_states__(socket, kind, module) do
    value_key = get_assigns_value_key(kind)
    call_functions? = should_call_functions?(kind)
    states = module.__states__(kind)

    Enum.reduce(states, socket, fn state, socket ->
      assign(socket, state, value_key, call_functions?, true)
    end)
  end

  defp assign(socket, attribute, value_key, call_functions?, force?) do
    value =
      if is_function(attribute[value_key]) && call_functions? do
        attribute[value_key].(socket)
      else
        attribute[value_key]
      end
    case force? do
      true -> Phoenix.LiveView.assign(socket, attribute.name, value)
      false -> Phoenix.LiveView.assign_new(socket, attribute.name, fn -> value end)
    end

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
    computed_states = for s <- states, s[:is_computed] == true && s[:after_connect] !=true, do: s
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
