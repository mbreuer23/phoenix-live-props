defmodule LiveProps.ValidationsTest do
  use ExUnit.Case

  test "raises on invalid attribute" do
    assert_raise ArgumentError, ~r/Attribute must be one of/, fn ->
      LiveProps.Validations.validate_opts!(:badattr, :name, :type, [])
    end
  end
end
