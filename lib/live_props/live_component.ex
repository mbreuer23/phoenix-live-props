defmodule LiveProps.LiveComponent do
  @moduledoc ~S'''
  When you `use LiveProps.LiveComponent` in your Phoenix LiveComponent, all of the functionality
  in `LiveProps.Props` and `LiveProps.States` will be imported.

  ### Example

      defmodule ButtonComponent do
        use Phoenix.LiveComponent
        use LiveProps.LiveComponent

        prop :class, :string, default: "button"
        prop :text, :string, default: "Click me"
        prop :on_click, :string, default: "click_button"

        def render(assigns) do
          ~L"""
          <button class="<%= @button %>"
                  phx-click="<%= @on_click %>">
            <%= @text %>
          </button>
          """
        end

  In this example we define three props that will be automatically assigned default values, so
  you don't have to define your own mount or update callbacks to do it yourself.

  More examples can be found in the `LiveProps` documentation.

  ### Component Lifecycle

  A Phoenix LiveComponent defines several callbacks, such as `mount/1`, `preload/1`, and `update/2`.
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

  If you define a `c.Phoenix.LiveComponent.preload/1` callback, which takes a list of assigns,
  default and computed props will be available in all assigns.

  ### Pitfalls

  If you try to pass a value to a LiveProps.LiveComponent and it has been declared
  in that component as a state, it will be ignored. (i.e. will not be assigned to the socket). State
  is meant only to be set within the socket or using `LiveProps.States.send_state/3` from a LiveView
  or another componenet. (You must use `LiveProps.States.send_state/3` rather
  than `Phoenix.LiveView.send_update/2`)


  '''

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
          callback = fn list -> super(list) end
          LiveProps.LiveComponent.__preload__(list_of_assigns, __MODULE__, callback)
        end
      end
    end
  end

  defp quoted_update(env) do
    preloaded = Module.defines?(env.module, {:preload, 1})

    if Module.defines?(env.module, {:update, 2}) do
      quote do
        defoverridable update: 2

        def update(assigns, socket) do
          callback = fn socket -> super(assigns, socket) end

          LiveProps.LiveComponent.__update__(
            assigns,
            socket,
            __MODULE__,
            unquote(preloaded),
            callback
          )
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
          callback = fn s -> super(s) end
          LiveProps.LiveComponent.__mount__(socket, __MODULE__, callback)
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

  def __mount__(socket, module, callback \\ nil) do
    # TODO: As of now async states are not treated any
    # differently in a live component, where socket should already be connected.
    # Should be warn the user if they try to user :after_connect option
    # in a component?
    socket
    |> LiveProps.__assign_states__(:defaults, module)
    |> LiveProps.__assign_states__(:computed, module)
    |> LiveProps.__assign_states__(:async, module)
    |> maybe_call_callback(callback)
  end

  def __preload__(list_of_assigns, module, callback) do
    case is_update_command(list_of_assigns) do
      false ->
        list_of_assigns
        |> Enum.map(fn assigns -> require_props!(assigns, module) end)
        |> put_props_in_list(module)
        |> callback.()

      true ->
        list_of_assigns
    end
  end

  def __update__(assigns, socket, module, preloaded?, callback \\ nil) do
    case {is_update_command(assigns), preloaded?} do
      {true, _} ->
        socket = LiveProps.__set_state__(socket, assigns, module)
        {:ok, socket}

      {_, true} ->
        require_props!(assigns, module)

        socket
        |> assign(assigns)
        |> maybe_call_callback(callback)

      {_, false} ->
        require_props!(assigns, module)

        socket
        |> assign(drop_states(assigns, module))
        |> LiveProps.__assign_props__(:defaults, module)
        |> LiveProps.__assign_props__(:computed, module)
        |> maybe_call_callback(callback)
    end
  end

  defp maybe_call_callback(socket, nil), do: {:ok, socket}
  defp maybe_call_callback(socket, callback), do: callback.(socket)

  defp put_props_in_list(list_of_assigns, module) do
    Enum.map(list_of_assigns, fn assigns ->
      assigns
      |> drop_states(module)
      |> LiveProps.__put_props__(:defaults, module)
      |> LiveProps.__put_props__(:computed, module)
    end)
  end

  defp is_update_command(%{lp_command: :set_state}), do: true

  defp is_update_command(list_of_assigns) when is_list(list_of_assigns) do
    list_of_assigns
    |> List.first()
    |> is_update_command()
  end

  defp is_update_command(_assigns), do: false

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

    assigns
  end
end
