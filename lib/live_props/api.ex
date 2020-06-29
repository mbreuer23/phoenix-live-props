defmodule LiveProps.API do
  @moduledoc """
  The LiveProps API.  Exposes two macros, `prop/3` and `state/3` which
  can be used inside Phoenix LiveViews and/or Phoenix LiveComponents
  """
  defmacro __using__(include: include) do
    imports = %{
      prop: [{:prop, 2}, {:prop, 3}],
      state: [{:state, 2}, {:state, 3}, {:send_state, 3}, {:set_state, 2}]
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
    LiveProps.API.Docs.generate_docs(env)
    [
      quoted_prop_api(env),
      quoted_state_api(env)
    ]
  end

  @doc """
  Define a property and given name and type. Returns `:ok`
  """
  defmacro prop(name, type, opts \\ []) do
    quote do
      LiveProps.API.__prop__(unquote(name), unquote(type), unquote(opts), __MODULE__)
    end
  end

  @doc """
  Define state of given name and type.  Returns :ok
  """
  defmacro state(name, type, opts \\ []) do
    quote do
      LiveProps.API.__state__(unquote(name), unquote(type), unquote(opts), __MODULE__)
    end
  end

  defmacro set_state(socket, assigns) do
    quote do
      LiveProps.API.__set_state__(unquote(socket), unquote(assigns), __MODULE__)
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

  def __assign_default_states__(socket, states) do
    states
    |> Stream.filter(&(&1.has_default == true))
    |> Enum.reduce(socket, fn state, socket ->
      Phoenix.LiveView.assign(socket, state.name, state.default)
    end)
  end

  defmacro assign_states(socket, kind) do
    quote bind_quoted: [socket: socket, kind: kind] do
      LiveProps.API.__assigns_states__(socket, kind, __MODULE__)
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
        attribute[value_key].(socket.assigns)
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

  def prefix(atom) when is_atom(atom) do
    ("liveprop_" <> Atom.to_string(atom))
    |> String.to_atom()
  end
end
