defmodule LiveProps.TestHelpers do
  defmacro assert_no_compile(message, do: do_block) do
    quote do
      assert_raise CompileError, unquote(message), fn ->
        defmodule Error do
          use LiveProps.API, include: [:prop]
          unquote(do_block)
        end
      end
    end
  end
end
