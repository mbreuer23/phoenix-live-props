defmodule LiveProps.API do
  @moduledoc """
  The LiveProps API.  Exposes two macros, `prop/3` and `state/3` which
  can be used inside Phoenix LiveViews and/or Phoenix LiveComponents
  """
  alias LiveProps.Utils

  defmacro __using__(include: include) do
    arities = %{
      prop: [2, 3],
      state: [2, 3]
    }

    functions = for func <- include, arity <- arities[func], into: [], do: {func, arity}
    attribute_names = for func <- include, into: [], do: derive_attribute_name(func)

    quote do
      import unquote(__MODULE__), only: unquote(functions)
      @before_compile unquote(__MODULE__)

      for func <- unquote(attribute_names) do
        Module.register_attribute(__MODULE__, func, accumulate: true)
      end
    end
  end

  defmacro __before_compile__(env) do
    [
      quoted_prop_api(env)
    ]
  end

  defmacro prop(name, type, opts \\ []) do
    build_attribute_ast(:live_prop, name, type, opts, __CALLER__)
  end

  defmacro state(name, type, opts \\ []) do
    build_attribute_ast(:live_state, name, type, opts, __CALLER__)
  end

  defp build_attribute_ast(attribute, name, type, opts, caller) do
    quote do
      attribute = unquote(attribute)
      name = unquote(name)
      type = unquote(type)
      opts = unquote(opts)
      caller = unquote(Macro.escape(caller))

      definition = LiveProps.Factory.build_attribute(attribute, caller, name, type, opts)

      Module.put_attribute(
        __MODULE__,
        attribute,
        definition
      )
    end
  end

  defp derive_attribute_name(type) when is_atom(type) do
    ("live_" <> Atom.to_string(type))
    |> String.to_atom()
  end

  defp quoted_prop_api(env) do
    props = Utils.get_attributes_in_order_defined(env.module, :live_prop)

    quote do
      def __props__ do
        unquote(Macro.escape(props))
      end

      def __get_prop_by_name__(name) when is_atom(name) do
        LiveProps.Prop.get_prop_by_name(__props__(), name)
      end

      def __assign_defaults_props__(socket) do
        LiveProps.Prop.assign_default_props(socket, __props__())
      end
    end
  end
end
