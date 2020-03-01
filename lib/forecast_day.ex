defmodule ForecastDay do
  def from_nws_periods!(nws_periods) do
    nws_periods
    |> group_days()
    |> Enum.map(&convert_group_to_day/1)
  end

  defp group_days(nws_periods) do
    nws_periods
    |> Enum.chunk_by(fn %{"startTime" => start_time} ->
      {:ok, start_datetime, _} = start_time |> DateTime.from_iso8601()

      start_datetime
      |> DateTime.to_date()
    end)
  end

  defp convert_group_to_day(day_group) do
  end
end
