defmodule WeatherDaysNerves do
  @moduledoc """
  Documentation for WeatherDays.
  """

  alias WeatherDaysNerves.Light

  @days_count 5

  @doc """
  Lights up LEDs based on 5 day forecast

  ## Examples

      iex> WeatherDays.lights_from_forecast()
      :ok

  """
  def lights_from_forecast() do
    with {:ok, forecast} <- get_forecast() do
      five_days = Enum.take(forecast, @days_count)
      forecast_with_leds = Enum.zip(five_days, days_leds())

      forecast_with_leds
      |> Enum.map(&light_from_forecast_day/1)

      # :ok
    end
  end

  defp light_from_forecast_day({%ForecastDay{status: status}, %Light{} = light}) do
    case status do
      :precipitation -> light |> Light.set_to_color(:blue)
      :clear -> light |> Light.set_to_color(:white)
    end
  end

  @doc """
  Retrieves current coordinates using IPstack API. Requires IPSTACK_ACCESS_KEY var to be set.

  ## Examples

      iex> WeatherDays.get_forecast()
      {:ok, [some_list_of_days...]}

  """
  def get_forecast() do
    with {:ok, public_ip} <- get_public_ip(),
         {:ok, {lon, lat}} <- get_coords_from_ip(public_ip),
         {:ok, wfo_url, _timezone} <- get_info_from_coords({lon, lat}),
         {:ok, forecast} <- get_forecast_from_wfo_url(wfo_url) do
      {:ok, forecast}
    end
  end

  def get_public_ip() do
    case http_client_module().get("https://api.ipify.org") do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        {:ok, body}

      e ->
        {:error, :couldnt_get_ip, inspect(e)}
    end
  end

  def get_coords_from_ip(ip) do
    access_key = Application.get_env(:weather_days_nerves, :ipstack_access_key)

    case http_client_module().get(
           "http://api.ipstack.com/#{ip}\?access_key\=#{access_key}\&fields\=longitude,latitude"
         ) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        %{"longitude" => lon, "latitude" => lat} = body |> Jason.decode!()
        {:ok, {lon, lat}}

      e ->
        {:error, :couldnt_get_coords_from_ip, inspect(e)}
    end
  end

  @doc """
  Gets the URL for a weather forecast office from the given coordinates.

      iex> get_info_from_coords({30.2897, -97.7665})
      "https://api.weather.gov/gridpoints/EWX/154,91/forecast"
  """
  def get_info_from_coords({lon, lat}) do
    url = "https://api.weather.gov/points/#{Float.round(lat, 3)},#{Float.round(lon, 3)}"

    with {:ok, %HTTPoison.Response{body: body, status_code: 200}} <-
           http_client_module().get(url),
         %{"properties" => %{"forecast" => forecast_url, "timeZone" => timezone}} <-
           Jason.decode!(body) do
      {:ok, forecast_url, timezone}
    else
      e -> {:error, :couldnt_get_wfo, inspect(e)}
    end
  end

  @doc """
  Gets a weather forecast from a weather forecast office's URL.

      iex> get_forecast_from_wfo_url("https://api.weather.gov/gridpoints/EWX/154,91/forecast)
      [some_forecast_item, ...]
  """
  def get_forecast_from_wfo_url(wfo_url) do
    with {:ok, %HTTPoison.Response{body: body, status_code: 200}} <-
           http_client_module().get(wfo_url),
         %{"properties" => %{"periods" => nws_periods}} <- Jason.decode!(body),
         weather_days <- ForecastDay.from_nws_periods!(nws_periods) do
      {:ok, weather_days}
    else
      e -> {:error, :couldnt_get_wfo, inspect(e)}
    end
  end

  @pins [2, 3, 14, 4, 15, 18, 17, 27, 23, 22, 24, 10, 25, 9, 8]
  def initialize_gpio() do
    Enum.map(@pins, fn number ->
      {:ok, pin} = Circuits.GPIO.open(number, :output)
      Circuits.GPIO.write(pin, 1)
      :timer.sleep(20)
      Circuits.GPIO.write(pin, 0)
      Circuits.GPIO.close(pin)
    end)
  end

  def days_leds() do
    @pins
    |> Enum.chunk_every(3)
    |> Enum.map(fn [r, g, b] ->
      %WeatherDaysNerves.Light{red: r, green: g, blue: b}
    end)
  end

  defp http_client_module(),
    do: Application.get_env(:weather_days_nerves, :http_client_module, HTTPoison)
end
