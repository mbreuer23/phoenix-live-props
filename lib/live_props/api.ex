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

    new_assigns =
      socket.assigns
      |> Map.merge(assigns)
      |> module.__put_computed_states__()
      |> module.__put_async_states__()
      |> Map.drop([:flash])

    Phoenix.LiveView.assign(socket, new_assigns)
  end

  def __prop__(name, type, opts, module) do
    define(:prop, name, type, opts, module)
  end

  def __state__(name, type, opts, module) do
    define(:state, name, type, opts, module)
  end

  def __put_default_props__(assigns, props) do
    props
    |> Stream.filter(&(&1.has_default == true))
    |> Enum.reduce(assigns, fn prop, assigns ->
      Map.put_new_lazy(assigns, prop.name, fn -> prop.default end)
    end)
  end

  def __put_computed_props__(assigns, props) do
    props
    |> Stream.filter(&(&1.is_computed == true))
    |> Enum.reduce(assigns, fn prop, assigns ->
      Map.put(assigns, prop.name, prop.compute.(assigns))
    end)
  end

  def __put_default_states__(assigns, states) do
    states
    |> Stream.filter(&(&1.has_default == true))
    |> Enum.reduce(assigns, fn state, assigns ->
      Map.put(assigns, state.name, state.default)
    end)
  end

  def __put_computed_states__(assigns, states, filter \\ nil) do
    states =
      case is_function(filter) do
        true ->
          states
          |> Stream.filter(&(&1.is_computed == true))
          |> Stream.filter(filter)

        false ->
          states
          |> Stream.filter(&(&1.is_computed == true))
      end

    Enum.reduce(states, assigns, fn state, assigns ->
      Map.put(assigns, state.name, state.compute.(assigns))
    end)
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

      def __put_default_props__(assigns) do
        LiveProps.API.__put_default_props__(assigns, __props__(:defaults))
      end

      def __put_computed_props__(assigns) do
        LiveProps.API.__put_computed_props__(assigns, __props__(:computed))
      end
    end
  end

  defp quoted_state_api(env) do
    states = Module.get_attribute(env.module, prefix(:state), []) |> Enum.reverse()
    default_states = for s <- states, s[:has_default] == true, do: s
    computed_states = for s <- states, s[:is_computed] == true, do: s

    quote do
      def __states__(:all), do: unquote(Macro.escape(states))
      def __states__(:defaults), do: unquote(Macro.escape(default_states))
      def __states__(:computed), do: unquote(Macro.escape(computed_states))

      def __put_default_states__(assigns) do
        LiveProps.API.__put_default_states__(assigns, __states__(:defaults))
      end

      def __put_computed_states__(assigns) do
        LiveProps.API.__put_computed_states__(
          assigns,
          __states__(:computed),
          &(&1[:after_connect] != true)
        )
      end

      def __put_async_states__(assigns) do
        LiveProps.API.__put_computed_states__(
          assigns,
          __states__(:computed),
          &(&1[:after_connect] == true)
        )
      end
    end
  end

  def prefix(atom) when is_atom(atom) do
    ("liveprop_" <> Atom.to_string(atom))
    |> String.to_atom()
  end
end
