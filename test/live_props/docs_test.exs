defmodule LiveProps.DocsTest do
  use ExUnit.Case

  defmodule InjectDocs do
    defmacro __before_compile__(_env) do
      quote do
        def docs do
          @moduledoc
        end
      end
    end
  end

  defmodule Component do
    use Phoenix.LiveComponent
    use LiveProps.LiveComponent

    @before_compile InjectDocs
    @moduledoc """
    Example docs
    """
    prop :prop1, :boolean, default: true
    prop :name, :true, compute: :get_name, doc: "The name of the user"

    def render(assigns) do
      ~L"""
      """
    end

    def get_name(_), do: "name"
  end

  test "generates docs" do
    assert {:module, _mod} = Code.ensure_compiled(Component)
    assert Component.docs() =~ "**prop1**"
    assert Component.docs() =~ "The name of the user"
  end
end
