defmodule LiveProps.APITest do
  use ExUnit.Case

  import LiveProps.TestHelpers

  alias Phoenix.LiveView.Socket

  # defmodule PropsTest do
  #   require LiveProps.API

  #   use LiveProps.API, include: [:prop]

  #   prop(:id, :atom, required: true)
  #   prop(:user, :map, required: false, default: %{id: 1})
  #   prop(:user_name, :string, compute: :get_user_name)
  #   prop(:user_name_2, :string, compute: &PropsTest.get_user_name/1)

  #   def get_user_name(assigns) do
  #     "user-#{assigns.user.id}"
  #   end
  # end

  describe "Props" do
  #   test "inject functions into using module" do
  #     functions =
  #       PropsTest.__info__(:functions)
  #       |> Map.new()

  #     assert %{
  #              __props__: 0,
  #              __get_prop_by_name__: 1,
  #              __assign_defaults_props__: 1
  #            } = functions
  #   end

  #   test "lists props" do
  #     assert 4 =
  #              PropsTest.__props__()
  #              |> length()
  #   end

  #   test "defines property correctly" do
  #     assert %{
  #              name: :id,
  #              type: :atom,
  #              module: PropsTest,
  #              required: true,
  #              doc: nil,
  #              has_default: false,
  #              default: nil,
  #              is_computed: false
  #            } = PropsTest.__get_prop_by_name__(:id)

  #     assert %{
  #              name: :user,
  #              type: :map,
  #              module: PropsTest,
  #              required: false,
  #              doc: nil,
  #              has_default: true,
  #              default: %{id: 1},
  #              is_computed: false
  #            } = PropsTest.__get_prop_by_name__(:user)

  #     assert %{
  #              name: :user_name,
  #              type: :string,
  #              module: PropsTest,
  #              required: false,
  #              doc: nil,
  #              has_default: false,
  #              default: nil,
  #              is_computed: true,
  #              compute: :get_user_name
  #            } = PropsTest.__get_prop_by_name__(:user_name)
  #   end
  end

  describe "Props Validations" do
    test "raises compile errors on invalid options" do
      assert_no_compile ~r/Name should be an atom/ do
        prop("prop1", :atom)
      end

      assert_no_compile ~r/Type should be an atom/ do
        prop(:prop, "type")
      end

      assert_no_compile ~r/defined more than once/ do
        prop(:prop, :boolean)
        prop(:prop, :atom)
      end

      assert_no_compile ~r/Invalid option/ do
        prop(:prop, :boolean, invalid_option: true)
      end

      assert_no_compile ~r/should be a keyword list/ do
        prop(:prop, :boolean, %{default: true})
      end

      assert_no_compile ~r/undefined function/ do
        prop(:test, :map, compute: &undef/1)
      end

      # assert_no_compile ~r/Undefined function/ do
      #   prop :test, :string, compute: &String.undefined_function/1
      # end

      # assert_no_compile ~r/Undefined function/ do
      #   prop :test, :string, compute: :test

      #   def test, do: false
      # end
    end
  end

  # describe "Props" do
  #   IO.inspect(PropsTest.__live_props__())
  # end
end
