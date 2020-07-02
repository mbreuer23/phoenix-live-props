defmodule LiveProps.TestHelpers do
  @moduledoc false
  defmacro assert_no_compile(error, message, do: do_block) do
    quote do
      assert_raise unquote(error), unquote(message), fn ->
        defmodule Error do
          @moduledoc false
          use LiveProps, include: [:prop, :state]
          unquote(do_block)
        end
      end
    end
  end
end
