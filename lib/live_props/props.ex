defmodule LiveProps.Props do
  @moduledoc """
  Functions for working with props.
  """

  @doc """
  Define a property with the given name and type. Returns `:ok`

  This macro is meant to be called within a LiveComponent only.
  Types can be any atom and are just for documentation purposes.

  ### Options:

    * `:default` - A default value to assign to the prop.
    * `:required` - boolean.  If true, an error will be raised
    if the prop is not passed to the component.
    * `:compute` - 1-arity function that takes the socket as an argument
    and returns the value to be assigned.  Can be an atom of the name
    of a function in your component or a remote function call like `&MyModule.compute/1`.
    If you use an atom, the referenced function must be **public**.
    % `:doc` - String.  Will be added to module documentation.
  """
  @spec prop(name :: atom(), type :: atom(), opts :: list()) :: :ok
  defmacro prop(name, type, opts \\ []) do
    quote do
      LiveProps.__prop__(unquote(name), unquote(type), unquote(opts), __MODULE__)
    end
  end
end
