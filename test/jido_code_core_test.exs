defmodule JidoCodeCoreTest do
  use ExUnit.Case
  doctest JidoCodeCore

  test "greets the world" do
    assert JidoCodeCore.hello() == :world
  end
end
