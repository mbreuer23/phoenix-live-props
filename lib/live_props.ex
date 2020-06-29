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

  In side a LiveView or LiveComponent, you must `use` `LiveProps.LiveView` or `LiveProps.LiveComponent`,
  respectively.

      defmodule MyAppWeb.ThermostatComponent do
        # If you generated an app with mix phx.new --live,
        # the line below would be: use MyAppWeb, :live_component
        use Phoenix.LiveComponent
        use LiveProps.LiveComponent

        prop :user_id, :integer, required: true
        prop :temperature, :float, compute: :get_temperature

        state :scale, :atom, default: :fahrenheit

        def render(assigns) do
          ~L"""
          Current temperature: <%= @temperature %>
          """
        end

        def get_temperature(assigns) do
          Thermostat.get_user_reading(assigns.user_id, assigns.scale)
        end

        def handle_event("toggle-scale", _, socket) do
            new_scale =
              if socket.assigns.scale == :fahrenheit,
                do: :celsius,
                else: :fahrenheit

            {:noreply,
              socket
              |> assign(:scale, new_scale)
              |> }
        end
      end

  Admittedly, we have not done much here.  We've just declared two states and their types,
  `:temperature` and `:user_id` using the `LiveProps.API.state/3` macro, but we've assigned
  their values in the usual way.  Still, depending on your preferences, you might like having
  a list of all known states at the top of your component.  Note that the type can be any atom.

  Let's look at another example.

        defmodule MyAppWeb.ThermostatLive do
          use Phoenix.LiveView

          def render(assigns) do
            ~L"""
            Current temperature: <%= @temperature %>, checked at: <%= inspect(@checked_at) %>
            <button phx-click="refresh">Refresh</button>
            """
          end

          def mount(_params, %{"current_user_id" => user_id}, socket) do
            {:ok,
              socket
              |> assign(:user_id, user_id)
              |> assign_temperature_data()}
          end

          def handle_event("refresh", _, socket) do
            {:noreply, assign_temperature_data(socket)}
          end

          defp assign_temperature_data(socket) do
            socket
            |> assign(:temperature, Thermostat.get_user_reading(socket.assigns.user_id))
            |> assign(:checked_at, Date.utc_now())}
          end
        end

  In this example we've added a `:checked_at` assign to show when the temperature we last refreshed
  and created a button to allow the user to manually refresh.  Finally, we've created a helper function
  to handle getting the temperature/time data.

        defmodule MyAppWeb.ThermostatLive do
          use Phoenix.LiveView
          use LiveProps.LiveView

          state :user_id, :integer
          state :temperature, :float, compute: :get_temp
          state :temperature_checked_at, :time, compute: :get_time

          def render(assigns) do
            ~L"""
            Current temperature: <%= @temperature %>, checked at: <%= inspect(@temperature_checked_at) %>
            <button phx-click="refresh">Refresh</button>
            """
          end

          def mount(_params, %{"current_user_id" => user_id}, socket) do
            {:ok, assign(socket, :user_id, user_id)}
          end

          def handle_event("refresh", _, socket) do
            {:ok, refresh_state(socket)}
          end

          def get_temperature(assigns) do
            Thermostat.get_user_reading(assigns.user_id)
          end

          def get_time(_assigns) do
            DateTime.utc_now()
          end

        end



  '''
end
