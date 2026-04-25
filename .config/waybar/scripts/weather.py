#!/usr/bin/env python3
import urllib.request
import json
from datetime import datetime

LAT = 28.5355
LON = 77.3910

WMO = {
    0:"☀️ Clear",1:"🌤 Mostly Clear",2:"⛅ Partly Cloudy",3:"☁️ Overcast",
    45:"🌫 Foggy",48:"🌫 Icy Fog",51:"🌦 Light Drizzle",53:"🌦 Drizzle",
    55:"🌧 Heavy Drizzle",61:"🌧 Light Rain",63:"🌧 Rain",65:"🌧 Heavy Rain",
    80:"🌦 Light Showers",81:"🌧 Showers",82:"⛈ Heavy Showers",
    95:"⛈ Thunderstorm",96:"⛈ Hail Storm",99:"⛈ Heavy Hail Storm",
}

url = (
    f"https://api.open-meteo.com/v1/forecast"
    f"?latitude={LAT}&longitude={LON}"
    f"&current=temperature_2m,apparent_temperature,relative_humidity_2m,"
    f"wind_speed_10m,wind_direction_10m,weathercode,is_day"
    f"&daily=weathercode,temperature_2m_max,temperature_2m_min,precipitation_sum"
    f"&forecast_days=5&timezone=Asia%2FKolkata"
)

with urllib.request.urlopen(url) as r:
    d = json.loads(r.read())

c = d["current"]
daily = d["daily"]

code = c["weathercode"]
desc = WMO.get(code, "?")
temp = round(c["temperature_2m"])
feels = round(c["apparent_temperature"])
hum = c["relative_humidity_2m"]
wind = round(c["wind_speed_10m"])
wdir = c["wind_direction_10m"]

# wind direction arrow
arrows = ["↑","↗","→","↘","↓","↙","←","↗"]
arrow = arrows[round(wdir / 45) % 8]

text = f"{desc} {temp}°C"

tooltip_lines = [
    f"<b>    Noida, UP     </b>",
    f"  {temp}°C  (feels {feels}°C)",
    f"  Humidity: {hum}%",
    f"  Wind: {wind} km/h {arrow}",
    "",
    f"<b>  5-Day Forecast  </b>",
    f"─────────────────────────",
]

days = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
for i in range(5):
    date = datetime.strptime(daily["time"][i], "%Y-%m-%d")
    day = days[date.weekday()]
    wcode = daily["weathercode"][i]
    hi = round(daily["temperature_2m_max"][i])
    lo = round(daily["temperature_2m_min"][i])
    rain = daily["precipitation_sum"][i]
    icon = WMO.get(wcode, "?").split()[0]
    tooltip_lines.append(f"{day}  {icon}  {hi}° / {lo}°  🌧 {rain}mm")

print(json.dumps({
    "text": text,
    "tooltip": "\n".join(tooltip_lines),
    "class": "weather"
}))