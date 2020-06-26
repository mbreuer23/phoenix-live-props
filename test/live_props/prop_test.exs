defmodule LiveProps.PropTest do
  use ExUnit.Case
  alias LiveProps.Prop
  alias Ecto.Changeset

  @valid_attrs %{module: :module, name: :name, type: :type}
  @invalid_attrs %{module: "Module", name: "name", type: "type"}

  describe "Prop" do
    test "new/1 returns a Prop with valid data" do
      assert {:ok, %Prop{} = prop} =
        Prop.new(@valid_attrs)

      assert @valid_attrs = prop
    end

    test "new/1 returns changeset with invalid data" do
      assert {:error, %Changeset{} = changeset} =
        Prop.new(@invalid_attrs)

      IO.inspect(changeset.errors)
    end
  end
end
