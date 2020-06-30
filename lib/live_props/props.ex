defmodule LiveProps.Props do
  @spec prop(name :: atom(), type :: atom(), opts :: list()) :: :ok
  defmacro prop(name, type, opts \\ []) do
    quote do
      LiveProps.__prop__(unquote(name), unquote(type), unquote(opts), __MODULE__)
    end
  end
end
