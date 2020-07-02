defmodule LiveProps.LiveComponent.CustomMountTest do
  use LiveProps.ConnCase

  defmodule LiveView do
    use Phoenix.LiveView
    use LiveProps.LiveView

    def render(assigns) do
      ~L"""
      <div>
        <%= live_component @socket, LiveProps.LiveComponent.CustomMountTest.ComponentWithMount %>
      </div>
      """
    end
  end

  defmodule ComponentWithMount do
    use Phoenix.LiveComponent
    use LiveProps.LiveComponent

    prop :prop1, :any, default: 1
    prop :prop2, :any, compute: :get_prop2
    state :state1, :any, default: 1
    state :custom_mount, :any, default: false

    def render(assigns) do
      ~L"""
      <div>prop1 = <%= inspect(@prop1) %></div>
      <div>prop2 = <%= inspect(@prop2) %></div>
      <div>state1 = <%= inspect(@state1) %></div>
      <%= if @custom_mount do %>
        Custom Mounted
      <% end %>
      """
    end

    def mount(socket) do
       {:ok, assign(socket, :custom_mount, true)}
    end

    def get_prop2(assigns) do
      assigns.prop1 + 2
    end
  end

  describe "ComponentNoMount" do
    test "renders", %{conn: conn} do
      {:ok, _view, html} = live_isolated(conn, LiveView)
      assert html =~ "prop1 = 1"
      assert html =~ "prop2 = 3"
      assert html =~ "state1 = 1"
      assert html =~ "Custom Mounted"
    end
  end
end
