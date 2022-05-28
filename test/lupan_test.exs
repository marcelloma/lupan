defmodule LupanTest do
  use ExUnit.Case
  doctest Lupan

  test "greets the world" do
    assert Lupan.hello() == :world
  end
end
