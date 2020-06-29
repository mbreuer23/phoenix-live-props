defmodule LiveProps do
  @moduledoc ~S'''
  LiveProps is a library for managing properties and state within Phoenix LiveViews
  and Phoenix LiveComponents.

  ### Features

    * Declaratively define props and state, initialize default values, and compute derived values
    using the `LiveProps.API.prop/3` and `LiveProps.API.state/3` macros.

    * Supports required props

    * Supports asynchronous loading of state.

    * Supports automatic re-computation of computed props and state

    * Props automatically added to module documentation.


  ### Example

  Inside a LiveView or LiveComponent, you must use `LiveProps.LiveView` or `LiveProps.LiveComponent`,
  respectively.  LiveComponents can have state and props, while a LiveView can only have state,
  so we'll look at an example LiveComponent to demonstrate both.

      defmodule MyAppWeb.ThermostatComponent do
        # If you generated an app with mix phx.new --live,
        # the line below would be: use MyAppWeb, :live_component
        use Phoenix.LiveComponent
        use LiveProps.LiveComponent

        prop :user_id, :integer, required: true
        prop :temperature, :float, compute: :get_temperature

        state :mode, :atom, default: :verbose

        def render(assigns) do
          ~L"""
          <%= case @mode  do %>
            <% :verbose -> %>
              Current temperature: <%= @temperature %>

            <% _ -> %>
              <%= @temperature %>
          <% end %>
          <button phx-click="toggle-mode" phx-target="<%= @myself %>">Toggle mode</button>
          """
        end

        def get_temperature(%{assigns: assigns} = _socket) do
          Thermostat.get_user_reading(assigns.user_id)
        end

        def handle_event("toggle-mode", _, socket) do
          new_mode =
            if socket.assigns.mode == :verbose,
              do: :compact,
              else: :verbose

          {:noreply, assign(socket, :mode, new_mode)}
        end
      end

  Our component requires a `:user_id` prop, which it uses to fetch the temperature.
  Since it is required, an error will be raised if you forget to pass it in.

  We also have the `:temperature` prop, which is a computed prop.  This will be re-calculated
  automatically anytime the :user_id prop changes.  It is calculated by `get_temperature/1` which
  takes the socket as an argument and returns the value to be assigned.  Calculations are run
  in the order defined so we could add even more computed props which depend on the temperature assign.

  Lastly, the component has a state called `:mode` which controls the display.  We've given
  it a default value, which is assigned on mount.  We could also add computed states
  which depends on other states.

  Notice what our component does not have: a `c:Phoenix.LiveComponent.mount/1` or `c:Phoenix.LiveComponent.update/2`
  callback.  LiveProps handles that for you, by injecting lightweight mount/1 and update/2 callbacks under the hood.
  In pseudocode, these callbacks look like the following:

      def mount(socket) do
        {:ok, assign_default_states(socket)}
      end

      def update(assigns, socket) do
        raise_if_missing_required_props!(assigns)

        {:ok, assign_props_and_computed_props(socket)}
      end

  While LiveProps defines `mount` and `update` callbacks for you.  You can still define your own
  and everything will continue to work.  In a LiveComponent, any mount or update callbacks
  you define will be run **after** the the LiveProps callbacks (i.e. defaults and computed values
  will already be assigned to the socket)
  '''
end
