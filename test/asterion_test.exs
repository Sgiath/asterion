defmodule AsterionTest do
  use ExUnit.Case
  doctest Asterion

  test "greets the world" do
    assert Asterion.hello() == :world
  end
end
