defmodule LiveProps.States do
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

  defmacro assign_states(socket, kind) do
    quote bind_quoted: [socket: socket, kind: kind] do
      LiveProps.__assigns_states__(socket, kind, __MODULE__)
    end
  end
end
