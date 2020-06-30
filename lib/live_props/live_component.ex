defmodule LiveProps.LiveComponent do
  @moduledoc """
  When you `use LiveProps.LiveComponent` in your Phoenix LiveComponent, all of the functionality
  in `LiveProps.Props` and `LiveProps.States` will be imported.

  An example LiveComponent can be found in the `LiveProps` documentation.

  ### Component Lifecycle

  A Phoenix LiveComponent defines several callbacks, such as `mount/1`, `preload/`, and `update/2`.
  LiveProps injects these callbacks under the hood so you don't have to (but you can if you want).

  If you do not define your own callbacks, the injected ones will be executed as follows:

          mount/1             --->    update/2
      (default and computed          (default and computed props
        states assigned)               merged/assigned)

  States and props will always be assigned in the order defined.

  If you do define a mount or update callback, they will be run **after** the associated
  callback injected by LiveProps.  In other words, in your mount/1 callback, default and calculated
  states will already be assigned to the socket.  In your update/2 callback, default and computed props
  will have been assigned too.

  If you define a `c.Phoenix.LiveComponent.update/2` callback, which takes a list of assigns,
  default and computed props will be available in all assigns.

  ### Pitfalls

  If you try to pass a value to a LiveProps.LiveComponent and it has not been declared
  in that component as a state using the `LiveProps.States.state/3` macro, it
  will be ignored. (i.e. will not be assigned to the socket).

  For related reasons, `Phoenix.LiveView.send_update/2` will not work with LiveProps LiveComponents,
  so you'll need to use `LiveProps.States.send_state/3` instead.

  """

  import Phoenix.LiveView
  require LiveProps

  defmacro __using__(_) do
    quote do
      use LiveProps, include: [:state, :prop]

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    [
      quoted_preload(env),
      quoted_update(env),
      quoted_mount(env)
    ]
  end

  defp quoted_preload(env) do
    if Module.defines?(env.module, {:preload, 1}) do
      quote do
        defoverridable preload: 1

        def preload(list_of_assigns) do
          list_of_assigns = LiveProps.LiveComponent.__preload__(list_of_assigns, __MODULE__)
          super(list_of_assigns)
        end
      end
    end
  end

  defp quoted_update(env) do
    preloaded = Module.defines?(env.module, {:preload, 1})

    if Module.defines?(env.module, {:update, 2}) do
      quote do
        defoverridable update: 2

        def update(%{lp_command: :set_state} = assigns, socket) do
          LiveProps.LiveComponent.__update__(assigns, socket, __MODULE__, unquote(preloaded))
        end

        def update(assigns, socket) do
          {:ok, socket} =
            LiveProps.LiveComponent.__update__(assigns, socket, __MODULE__, unquote(preloaded))

          super(assigns, socket)
        end
      end
    else
      quote do
        def update(assigns, socket) do
          LiveProps.LiveComponent.__update__(assigns, socket, __MODULE__, unquote(preloaded))
        end
      end
    end
  end

  defp quoted_mount(env) do
    if Module.defines?(env.module, {:mount, 1}) do
      quote do
        defoverridable mount: 1

        def mount(socket) do
          {:ok, socket} = LiveProps.LiveComponent.__mount__(socket, __MODULE__)
          super(socket)
        end
      end
    else
      quote do
        def mount(socket) do
          LiveProps.LiveComponent.__mount__(socket, __MODULE__)
        end
      end
    end
  end

  def __preload__(list_of_assigns, module) do
    Enum.map(list_of_assigns, fn
      %{lp_command: :set_state} = assigns ->
        assigns

      assigns ->
        assigns
        |> drop_states(module)
        |> LiveProps.__put_props__(:defaults, module)
        |> LiveProps.__put_props__(:computed, module)
    end)
  end

  def __update__(%{lp_command: :set_state} = assigns, socket, module, _preloaded) do
    new_assigns = Map.drop(assigns, [:lp_command, :id])

    {:ok,
     socket
     |> LiveProps.__set_state__(new_assigns, module)}
  end

  def __update__(assigns, socket, module, preloaded?) do
    require_props!(assigns, module)

    socket =
      case preloaded? do
        true ->
          socket
          |> assign(assigns)

        false ->
          socket
          |> assign(drop_states(assigns, module))
          |> LiveProps.__assign_props__(:defaults, module)
          |> LiveProps.__assign_props__(:computed, module)
      end

    {:ok, socket}
  end

  def __mount__(socket, module) do
    # TODO: As of now async states are not treated any
    # differently in a live component, where socket should already be connected.
    # Should be warn the user if they try to user :after_connect option
    # in a component?
    {:ok,
     socket
     |> LiveProps.__assign_states__(:defaults, module)
     |> LiveProps.__assign_states__(:computed, module)
     |> LiveProps.__assign_states__(:async, module)}
  end

  defp drop_states(assigns, module) do
    states = for s <- module.__states__(:all), do: s.name
    Map.drop(assigns, states)
  end

  defp require_props!(assigns, module) do
    required_keys = for p <- module.__props__(:required), do: p.name
    provided_keys = Map.keys(assigns)

    case required_keys -- provided_keys do
      [] ->
        :ok

      missing ->
        raise RuntimeError, """
        Missing required props:
        #{inspect(missing)}

        Recieved: #{inspect(assigns)}
        """
    end
  end
end
