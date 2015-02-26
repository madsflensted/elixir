 defmodule IEx.History.Ets do
  @moduledoc false

  @doc """
  Initializes ETS with iex_history table
  All history information is kept in ETS
  """
  def init do
    :ets.new(:iex_history, [:ordered_set, :named_table])
    :ets.insert(:iex_history, {:iex_history_start_counter, 1})
    :ets.insert(:iex_history, {:iex_history_counter, 1})
  end

  @doc """
  Appends one entry to the history with the given counter.
  """
  def append(entry, counter, limit) do
    :ets.insert(:iex_history, {counter, entry})
    :ets.update_counter(:iex_history, :iex_history_counter, 1)

    [{_, start_counter}] = :ets.lookup(:iex_history, :iex_history_start_counter)
    limit_history(start_counter, counter, limit)
  end

  defp limit_history(_, _, limit) when limit < 0 do
    nil
  end

  defp limit_history(counter, max_counter, limit) when max_counter - counter < limit do
    :ets.insert(:iex_history, {:iex_history_start_counter, counter})
  end

  defp limit_history(counter, max_counter, limit) do
    :ets.delete(:iex_history, counter)
    limit_history(counter+1, max_counter, limit)
  end

  @doc """
  Removes all entries from the history and forces a garbage collection cycle.
  """
  def reset() do
    try do
      :ets.delete(:iex_history)
    rescue
      e -> nil
    end
    init()
  end

  @doc """
  Enumerates over all items in the history starting from the oldest one and
  applies `fun` to each one in turn.
  """
  def each(fun) do
    each_pair(:ets.first(:iex_history), fun)
  end

  defp each_pair(:"$end_of_table", _) do
  end

  defp each_pair(:iex_history_start_counter, fun) do
    each_pair(:ets.next(:iex_history, :iex_history_start_counter), fun)
  end

  defp each_pair(:iex_history_counter, fun) do
    each_pair(:ets.next(:iex_history, :iex_history_counter), fun)
  end

  defp each_pair(key, fun) do
    [{_, val}] = :ets.lookup(:iex_history, key)
    fun.(val)
    each_pair(:ets.next(:iex_history, key), fun)
  end

  @doc """
  Gets the nth item from the history.

  If `n` < 0, the count starts from the most recent item and goes back in time.
  """

  def nth(n)
  when n < 0
  do
    [{_, counter}] = :ets.lookup(:iex_history, :iex_history_counter)
    nth(counter + n)
  end
  
  def nth(n)
  do
    case :ets.lookup(:iex_history, n) do
      [{_, entry}] -> entry
      [] -> raise "v(#{n}) is out of bounds"
    end
  end
  
  #   raise "v(#{n}) is out of bounds"
end
