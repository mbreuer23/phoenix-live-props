defmodule LiveProps.LiveComponentTest do
  use ExUnit.Case
  alias Phoenix.LiveView.Socket

  describe "LiveComponent" do
    defmodule Component do
      use Phoenix.LiveComponent
      use LiveProps.LiveComponent

      prop :id, :atom
      prop :authenticated, :boolean, default: false, required: true
      prop :count, :integer, compute: :get_count

      state :ready, :boolean, default: false
      state :items, :list, compute: :get_items

      def render(assigns) do
        ~L"""
        <%= @ready %>
        """
      end

      def update(_assigns, socket) do
        {:ok, assign(socket, :custom_update, true)}
      end

      def mount(socket) do
        {:ok, assign(socket, :custom_mount, true)}
      end

      def get_count(_), do: 10
      def get_items(%{assigns: assigns}) do
        case assigns[:ready] do
          :updated ->
            [:updated_items]
          _ ->
            [:items]
        end
      end
    end

    test "mounts properly" do
      {:ok, socket} = Component.mount(%Socket{})

      # defaults assigned
      assert socket.assigns[:ready] == false
      assert socket.assigns[:items] == [:items]

      # custom mount is respected
      assert socket.assigns[:custom_mount] == true

      # props not yet available
      for k <- [:id, :authenticated, :count] do
        assert Map.has_key?(socket.assigns, k) == false
      end

    end

    test "updates correctly" do
      {:ok, socket} = Component.update(%{authenticated: true, ready: :ready}, %Socket{})

      # passes props
      assert socket.assigns.authenticated == true

      # blocks states from being passed in
      assert Map.has_key?(socket.assigns, :ready) == false

      # respects custom update
      assert socket.assigns.custom_update == true
    end

    test "raises on missing required props" do
      assert_raise RuntimeError, ~r/Missing required props/, fn ->
        Component.update(%{}, %Socket{})
      end
    end

    test "allows state to be passed in with :lp_command" do
      {:ok, socket} = Component.mount(%Socket{})
      assert socket.assigns.ready == false
      assert socket.assigns.items == [:items]

      {:ok, socket} = Component.update(%{
        lp_command: :set_state,
        ready: :updated
      }, socket)

      assert socket.assigns.ready == :updated
      assert socket.assigns.items == [:updated_items]
    end
  end
end
