defmodule LiveProps.CreateViews do
  @moduledoc false
  defmacro view(name, block) do
    quote do
      LiveProps.CreateViews.__view__(unquote(name), unquote(Macro.escape(block)), __ENV__)
    end
  end

  defmacro component(name, block) do
    quote do
     LiveProps.CreateViews.__component__(unquote(name), unquote(Macro.escape(block)), __ENV__)
    end
  end

  def __view__(name, block, env) do
    contents =
      quote do
        use Phoenix.LiveView
        use LiveProps.LiveView

        unquote(block)
      end

    Module.create(name, contents, Macro.Env.location(env))
  end

  def __component__(name, block, env) do
    contents =
      quote do
        use Phoenix.LiveComponent
        use LiveProps.LiveComponent

        unquote(block)
      end

    Module.create(name, contents, Macro.Env.location(env))
  end
end
