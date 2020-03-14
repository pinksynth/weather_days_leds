defmodule WeatherDaysNerves.Updater do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_) do
    WeatherDaysNerves.lights_from_forecast()
    schedule_lights()
    {:ok, nil}
  end

  def handle_info(:update, _) do
    WeatherDaysNerves.initialize_gpio()
    WeatherDaysNerves.lights_from_forecast()
    schedule_lights()
    {:noreply, nil}
  end

  defp schedule_lights do
    Process.send_after(self(), :update, fifteen_minutes())
  end

  defp fifteen_minutes() do
    1000 * 60 * 15
  end
end
