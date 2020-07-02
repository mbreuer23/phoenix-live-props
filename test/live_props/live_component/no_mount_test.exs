defmodule LiveProps.LiveComponent.NoMountTest do
  use LiveProps.ConnCase
  import LiveProps.CreateViews

  view LiveView do
    def render(assigns) do
      ~L"""
      <div>
        <%= live_component @socket, ComponentNoMount %>
      </div>
      """
    end
  end

  component ComponentNoMount do
    prop :prop1, :any, default: 1
    prop :prop2, :any, compute: :get_prop2
    state :state1, :any, default: 1

    def render(assigns) do
      ~L"""
      <div>prop1 = <%= inspect(@prop1) %></div>
      <div>prop2 = <%= inspect(@prop2) %></div>
      <div>state1 = <%= inspect(@state1) %></div>
      """
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
    end
  end



  test "raises on missing props", %{conn: conn} do
    view Parent2 do
      def render(assigns) do
        ~L"""
        <%= live_component @socket, Child2 %>
        """
      end
    end

    component Child2 do
      prop :prop1, :any, required: true

      def render(assigns) do
        ~L"""
        <div>hi</div>
        """
      end
    end

    assert_raise RuntimeError, ~r/Missing required props/, fn ->
      {:ok, _, _} = live_isolated(conn, Parent2)
    end

  end
end
