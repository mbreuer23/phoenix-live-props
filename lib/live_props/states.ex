defmodule LiveProps.States do
  @doc """
  Define state of given name and type.  Returns :ok.

  Types can be any atom and are just for documentation purposes.

  ### Options:

    * `:default` - A default value that will be assigned on mount.
    * `:compute` - 1-arity function that takes the socket as an argument
    and returns the value to be assigned.  Can be an atom of the name
    of a function in your component or a remote function call like `&MyModule.compute/1`.
    If you use an atom, the referenced function must be **public**.
    * `:after_connect` - boolean.  Only applies in LiveViews.  Setting this to true
    will cause the initial value to be computed asynchronously after the socket connects.
  """
  @spec state(name :: atom(), type :: atom(), opts :: list()) :: :ok
  defmacro state(name, type, opts \\ []) do
    quote do
      LiveProps.__state__(unquote(name), unquote(type), unquote(opts), __MODULE__)
    end
  end

  @doc """
  Same as `set_state/3` but with a list or map of assigns.
  """
  @spec set_state(socket :: Phoenix.LiveView.Socket.t(), assigns :: list() | map()) ::
          Phoenix.LiveView.Socket.t()
  defmacro set_state(socket, assigns) do
    quote do
      LiveProps.__set_state__(unquote(socket), unquote(assigns), __MODULE__)
    end
  end

  @doc """
  Assign the state to the socket and return the socket.  This will also
  trigger re-calculation of any computed state.  If you do not wish to do this,
  use `Phoenix.LiveView.assign/3` instead.

  If the given `state` is has not been declared as a state, it will be ignored.
  """
  @spec set_state(socket :: Phoenix.LiveView.Socket.t(), state :: atom(), value :: any()) ::
          Phoenix.LiveView.Socket.t()
  defmacro set_state(socket, state, value) do
    quote do
      LiveProps.__set_state__(unquote(socket), %{unquote(state) => unquote(value)}, __MODULE__)
    end
  end

  @doc """
  Same as `set_state/2` but raises if passed an invalid state
  """
  @spec set_state!(socket :: Phoenix.LiveView.Socket.t(), assigns :: list() | map()) ::
  Phoenix.LiveView.Socket.t()
  defmacro set_state!(socket, assigns) do
    quote do
      LiveProps.__set_state__!(unquote(socket), unquote(assigns), __MODULE__)
    end
  end

  @doc """
  Same as `set_state/3` but raises if passed an invalid state
  """
  @spec set_state!(socket :: Phoenix.LiveView.Socket.t(), state :: atom(), value :: any()) ::
  Phoenix.LiveView.Socket.t()
  defmacro set_state!(socket, state, value) do
    quote do
      LiveProps.__set_state__!(unquote(socket), %{unquote(state) => unquote(value)}, __MODULE__)
    end
  end

  @doc """
  A replacement for `Phoenix.LiveView.send_update/2`.  Invalid states will be ignored.
  """
  @spec send_state(module :: module(), id :: any(), assigns :: list()) :: :ok
  def send_state(module, id, assigns) do
    Phoenix.LiveView.send_update(module, [lp_command: :set_state, id: id] ++ assigns)
  end

  @doc """
  Assign states of the given kind to the socket.  The kind can be
  one of  `:all`, `:defaults`, `:computed` (computed states without the `:after_connect` option), or `:async` (computed states
  defined with `after_connect: true`)
  """
  defmacro assign_states(socket, kind) do
    quote bind_quoted: [socket: socket, kind: kind] do
      LiveProps.__assigns_states__(socket, kind, __MODULE__)
    end
  end
end
