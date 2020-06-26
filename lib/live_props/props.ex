defmodule LiveProps.Props do
  defmacro __using__(include: include) do
    quote do
      import LiveProps.Props, only: unquote(include)
      @before_compile unquote(__MODULE__)

      Module.register_attribute(__MODULE__, unquote(prefix(:prop)), accumulate: true)
    end
  end

  defmacro __before_compile__(env) do
    if Module.has_attribute?(env.module, prefix(:prop)) do
      IO.puts("has props")
    end

    if Module.has_attribute?(env.module, prefix(:state)) do
      IO.puts("has state")
    end

    []
  end

  defmacro prop_list(do: block) do
    data_list(__CALLER__, :prop, block)
  end

  defmacro state_list(do: block) do
    data_list(__CALLER__, :state, block)
  end

  defmacro prop(name, type, opts \\ []) when is_atom(name) and is_atom(type) and is_list(opts) do
    quote do
      LiveProps.Props.__prop__(__MODULE__, unquote(name), unquote(type), unquote(opts))
    end
  end

  defmacro state(name, type, opts \\ []) when is_atom(name) and is_atom(type) and is_list(opts) do
    quote do
      LiveProps.Props.__state__(__MODULE__, unquote(name), unquote(type), unquote(opts))
    end
  end

  defp data_list(caller, kind, block) do
    prelude =
      quote do
        list_defined_attribute = unquote(prefix(kind, :list_defined))
        data_attribute = unquote(prefix(kind))

        if line = Module.get_attribute(__MODULE__, list_defined_attribute) do
          raise "#{unquote(kind)} list already defined for #{inspect(__MODULE__)} on line #{line}"
        end

        Module.put_attribute(__MODULE__, list_defined_attribute, unquote(caller.line))

        try do
          import LiveProps.Props, only: [{unquote(kind), 2}, {unquote(kind), 3}]
          unquote(block)
        after
          :ok
        end
      end


    postlude =
      quote unquote: false do
        data = Module.get_attribute(__MODULE__, data_attribute) |> Enum.reverse()

        def __liveprops__(kind), do: unquote(Macro.escape(data))
      end

    quote do
      unquote(prelude)
      unquote(postlude)
    end
  end

  def __prop__(module, name, type, options) do
    define_data(:prop, module, name, type, options)
  end

  def __state__(module, name, type, options) do
    define_data(:state, module, name, type, options)
  end



  defp define_data(kind, module, name, _type, _options) do
    Module.put_attribute(module, prefix(kind), name)
  end

  defp prefix(atom) do
    "liveprops_#{atom}" |> String.to_atom()
  end

  defp prefix(atom, extra) do
    "liveprops_#{atom}_#{extra}" |> String.to_atom()
  end
end

