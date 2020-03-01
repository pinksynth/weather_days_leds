defmodule WeatherDaysNervesTest do
  use ExUnit.Case

  describe("get_forecast/0") do
    test "returns the forecast" do
      assert {:ok, [%{} | _]} = WeatherDaysNerves.get_forecast()
    end
  end
end
