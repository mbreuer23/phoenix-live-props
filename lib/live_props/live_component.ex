defmodule LiveProps.LiveComponent do
  import Phoenix.LiveView
  defmacro __using__(_) do
    quote do
      use LiveProps.API, include: [:state, :prop]

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    [
      quoted_update(env),
      quoted_mount(env)
    ]
  end

  defp quoted_update(env) do
    if Module.defines?(env.module, {:update, 2}) do
      quote do
        defoverridable update: 2

        def update(%{lp_command: :set_state} = assigns, socket) do
          LiveProps.LiveComponent.__update__(assigns, socket, __MODULE__)
        end

        def update(assigns, socket) do
          {:ok, socket} = LiveProps.LiveComponent.__update__(assigns, socket, __MODULE__)
          super(assigns, socket)
        end
      end
    else
      quote do
        def update(assigns, socket) do
          LiveProps.LiveComponent.__update__(assigns, socket, __MODULE__)
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

  def __update__(%{lp_command: :set_state} = assigns, socket, module) do
    assigns = assigns |> Map.drop([:lp_command])

    socket = LiveProps.API.__set_state__(socket, assigns, module)

    {:ok, socket}
  end

  def __update__(assigns, socket, module) do
    require_props!(assigns, module)

    assigns =
      assigns
      |> drop_states(module)
      |> module.__put_default_props__()
      |> module.__put_computed_props__()

    {:ok, assign(socket, assigns)}
  end

  def __mount__(socket, module) do
    # TODO: As of now async states are not treated any
    # differently in a live component, where socket should already be connected.
    # Should be warn the user if they try to user :after_connect option
    # in a component?

    assigns =
      socket.assigns
      |> module.__put_default_states__()
      |> module.__put_computed_states__()
      |> module.__put_async_states__()


    {:ok, assign(socket, assigns)}
  end

  # def send_state(module, id, assigns) do
  #   send self(), {:liveprops, :send_state, [module, id, assigns]}
  # end

  defp drop_states(assigns, module) do
    states = for s <- module.__states__(:all), do: s.name
    Map.drop(assigns, states)
  end

  defp require_props!(assigns, module) do
    required_keys = for p <- module.__props__(:all), p[:required] == true, do: p.name
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
