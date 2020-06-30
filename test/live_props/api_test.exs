defmodule LiveProps.APITest do
  use ExUnit.Case

  import LiveProps.TestHelpers

  describe "Module ValidProps" do
    defmodule ValidProps do
      require LiveProps

      use LiveProps, include: [:prop]

      prop(:id, :atom, required: true)
      prop(:user, :map, required: false, default: %{id: 1})
      prop(:user_name, :string, compute: :get_user_name)
      prop(:user_name_2, :string, compute: &ValidProps.get_user_name/1)
      # prop(:identity, :integer, compute: fn _ -> 1 end)

      def get_user_name(assigns) do
        "user-#{assigns.user.id}"
      end
    end

    test "has props defined correctly" do
      names = for p <- ValidProps.__props__(:all), do: p.name
      required = for p <- ValidProps.__props__(:required), do: p.name
      defaults = for p <- ValidProps.__props__(:defaults), do: p.name
      computed = for p <- ValidProps.__props__(:computed), do: p.name

      assert [:id, :user, :user_name, :user_name_2] == names
      assert [:id] == required
      assert [:user] == defaults
      assert [:user_name, :user_name_2] == computed
    end
  end

  describe "Module ValidStates" do
    alias Phoenix.LiveView.Socket

    defmodule ValidStates do
      use LiveProps, include: [:state]

      state(:ready, :boolean, default: false)
      state(:count, :integer, compute: :get_count)
      state(:async_count, :integer, compute: :get_count, after_connect: true)
      state :no_default, :atom

      def get_count(_socket) do
        System.unique_integer()
      end
    end

    test "defines states" do
      states = for s <- ValidStates.__states__(:all), do: s.name
      defaults = for s <- ValidStates.__states__(:defaults), do: s.name
      computed = for s <- ValidStates.__states__(:computed), do: s.name
      async = for s <- ValidStates.__states__(:async), do: s.name

      assert [:ready, :count, :async_count, :no_default] == states
      assert [:ready] == defaults
      assert [:count] == computed
      assert [:async_count] = async
    end

    test "can set states" do
      socket = LiveProps.__set_state__(%Socket{}, %{ready: :ready}, ValidStates)
      assert socket.assigns.ready == :ready

      # invalid states ignored
      socket = LiveProps.__set_state__(socket, %{not_a_state: true}, ValidStates)
      refute Map.has_key?(socket.assigns, :not_a_state)

      # assert_raise RuntimeError, ~r/Cannot set state/, fn ->
      #   LiveProps.__set_state__(%Socket{}, %{not_a_state: true}, ValidStates)
      # end
    end
  end

  describe "Props Validations" do
    test "raises compile errors on invalid options" do
      assert_no_compile ArgumentError, ~r/Name should be an atom/ do
        prop("prop1", :atom)
      end

      assert_no_compile ArgumentError, ~r/Type should be an atom/ do
        prop(:prop, "type")
      end

      assert_no_compile ArgumentError, ~r/defined more than once/ do
        prop(:prop, :boolean)
        prop(:prop, :atom)
      end

      assert_no_compile ArgumentError, ~r/Invalid option/ do
        prop(:prop, :boolean, invalid_option: true)
      end

      assert_no_compile ArgumentError, ~r/should be a keyword list/ do
        prop(:prop, :boolean, %{default: true})
      end

      assert_no_compile CompileError, ~r/undefined function/ do
        prop(:test, :map, compute: &undef/1)
      end

      assert_no_compile ArgumentError, ~r/function or an atom/ do
        prop :test, :boolean, compute: 1
      end

      assert_no_compile ArgumentError, ~r/should be a boolean/ do
        prop :test, :boolean, required: :not_a_boolean
      end
    end
  end

  describe "State Validations" do
    test "raise errors" do
      assert_no_compile ArgumentError, ~r/must pass :compute/ do
        state(:state1, :map, after_connect: true)
      end

      assert_no_compile ArgumentError, ~r/must be a boolean/ do
        state(:state1, :map, compute: :do_compute, after_connect: 1)
      end
    end
  end
end
