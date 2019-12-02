# 8266_weather_station
Simple weather station ESP8266 with 0.96 i2c OLED

![Box shot](./screenshot/weather_box.png)


These are three configuration in lua script,

1. In "apconn.lua", you must specify SSID/Password or using enduser_setup.
2. In "weather.lua", yout must specify OpenWeatherMap AppId and latitude, longitude.
  It can also specify in "weconfig.lua" file. (_G.appid="" _G.lat="" _G.lon="")
3. In "weather.lua", you specify your local time offset from GMT time. (Set automatically in weather information)

wifi Enduser_setup,

1. wait for message "No Internet"
2. connect wifi to "weather_xxxxxx"
3. Enter URL "192.168.4.1"
4. Specify SSID and Password
5. Reboot or wait reboot in 5 minutes

SDA -> 8266 pin 1,
SCL -> 8266 pin 2,
VCC -> 3.3v,
GND -> GND

Weather information update every 5 minutes and display to post 6 hours informations.

code must be uploaded with binary transfer mode.
