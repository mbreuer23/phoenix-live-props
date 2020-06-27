defmodule LiveProps.APITest do
  use ExUnit.Case

  import LiveProps.TestHelpers

  describe "Module ValidProps" do
    defmodule ValidProps do
      require LiveProps.API

      use LiveProps.API, include: [:prop]

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

    test "puts default props correctly" do
      # assign doesnt exist
      assigns = ValidProps.__put_default_props__(%{})

      assert %{
               user: %{id: 1}
             } = assigns

      # assign already exists
      assigns = ValidProps.__put_default_props__(%{user: %{id: 3}})

      assert %{
               user: %{id: 3}
             } = assigns
    end

    test "computes props" do
      assigns = %{user: %{id: 1}}
      assigns = ValidProps.__put_computed_props__(assigns)
      assert assigns.user_name == "user-1"
      assert assigns.user_name_2 == "user-1"
    end
  end

  describe "Module ValidStates" do
    defmodule ValidStates do
      use LiveProps.API, include: [:state]

      state(:ready, :boolean, default: false)
      state(:count, :integer, compute: :get_count)
      state(:async_count, :integer, compute: :get_count, after_connect: true)

      def get_count(_assigns) do
        System.unique_integer()
      end
    end

    test "defines states" do
      states = for s <- ValidStates.__states__(:all), do: s.name
      defaults = for s <- ValidStates.__states__(:defaults), do: s.name
      computed = for s <- ValidStates.__states__(:computed), do: s.name

      assert [:ready, :count, :async_count] == states
      assert [:ready] == defaults
      assert [:count, :async_count] == computed
    end

    test "puts default states" do
      assigns = ValidStates.__put_default_states__(%{})
      assert assigns.ready == false
      refute Map.has_key?(assigns, :count)
      refute Map.has_key?(assigns, :async_count)
    end

    test "puts computed states" do
      assigns = ValidStates.__put_computed_states__(%{})
      assert is_integer(assigns.count)
      refute Map.has_key?(assigns, :async_count)
    end

    test "puts async states" do
      assigns = ValidStates.__put_async_states__(%{})
      assert is_integer(assigns.async_count)
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
