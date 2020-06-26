defmodule LiveProps.PropsTest do
  use ExUnit.Case

  defmodule Example do
    use LiveProps.Props, include: [prop_list: 1]
    prop_list do
      prop :prop1, :string, default: "default"
      prop :prop2, :boolean, default: true
    end
  end

  test "props are defined" do
    IO.inspect(Example.__liveprops__(:props))
  end
end
