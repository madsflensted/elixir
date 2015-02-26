Code.require_file "../test_helper.exs", __DIR__

defmodule IEx.HistoryTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias IEx.History.Ets, as: History

  setup do
    History.init

    on_exit fn ->
      History.reset
    end
  end

  @dummy_entry {1,2,3}

  test "append and retrieve entry" do
    History.append(@dummy_entry, 1, 20)
    assert History.nth(1) == @dummy_entry
  end

  test "nth raises out of bounds exception" do
    assert_raise RuntimeError, "v(1) is out of bounds", fn -> History.nth(1) == @dummy_entry end
  end

  defp add_many(count, max) do
    for n <- 1..count, do: History.append({"dummy", n}, n, max)
  end

  test "nth counting from beginning" do
    add_many(20, 20)
    assert History.nth(4) == {"dummy", 4}
  end

  test "nth counting from the end" do
    add_many(20, 20)
    assert History.nth(-1) == {"dummy", 20}
    assert History.nth(-4) == {"dummy", 17}
  end

  test "each print" do
    add_many(5, 20)
    output = capture_io(fn -> History.each(&IO.inspect/1) end)
    assert output == "{\"dummy\", 1}\n{\"dummy\", 2}\n{\"dummy\", 3}\n{\"dummy\", 4}\n{\"dummy\", 5}\n" 
  end

  test "each empty" do
    output = capture_io(fn -> History.each(&IO.inspect/1) end)
    assert output == ""
  end

  test "each count > max" do
    add_many(10, 5)
    output = capture_io(fn -> History.each(&IO.inspect/1) end)
    assert output == "{\"dummy\", 6}\n{\"dummy\", 7}\n{\"dummy\", 8}\n{\"dummy\", 9}\n{\"dummy\", 10}\n" 
  end
end
