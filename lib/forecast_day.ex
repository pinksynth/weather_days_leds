defmodule ForecastDay do
  defstruct [:status, :conditions_list, :temps_list]

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
    conditions_for_day = day_group |> Enum.map(& &1["shortForecast"])
    temps_for_day = day_group |> Enum.map(& &1["temperature"])
    has_precipitation = conditions_for_day |> Enum.any?(&condition_is_precipitation_like/1)

    status =
      cond do
        has_precipitation -> :precipitation
        # TODO: Introduce cloudy, sunny, etc
        true -> :clear
      end

    %ForecastDay{status: status, conditions_list: conditions_for_day, temps_list: temps_for_day}
  end

  @precipitation_words ["rain", "hail", "sleet", "snow", "drizzle", "shower", "precipit", "storm"]
  defp condition_is_precipitation_like(condition) do
    @precipitation_words
    |> Enum.reduce(false, fn word, precipitation_like? ->
      precipitation_like? or Regex.match?(~r/#{word}/i, condition)
    end)
  end
end
