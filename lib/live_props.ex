defmodule LiveProps do
  @moduledoc ~S'''
  LiveProps is a library for managing properties and state within Phoenix LiveViews
  and Phoenix LiveComponents.

  ### Features

    * Declaratively define props and state, initialize default values, or compute derived values
    using the `LiveProps.API.prop/3` and `LiveProps.API.state/3` macros.  State can be defined
    in LiveViews and LiveComponents, while props can only be defined in LiveComponents

    * Supports required props

    * Supports asynchronous loading of state.

    * Automatic re-computation of computed props and state

    * Props automatically added to module documentation.


  ### Example

  In side a LiveView or LiveComponent, you must use `LiveProps.LiveView` or `LiveProps.LiveComponent`,
  respectively.

      defmodule MyAppWeb.ThermostatLive do
        # If you generated an app with mix phx.new --live,
        # the line below would be: use MyAppWeb, :live_view
        use Phoenix.LiveView
        use LiveProps.LiveView

        state :temperature, :number,

        def render(assigns) do
          ~L"""
          Current temperature: <%= @temperature %>
          """
        end
      end

  '''
end
