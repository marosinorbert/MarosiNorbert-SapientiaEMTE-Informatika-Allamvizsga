#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <DHT.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// WiFi
const char* WIFI_SSID = "Marosi";
const char* WIFI_PASSWORD = "Marosi65A";

// Backend ngrok URL
const char* API_BASE_URL = "https://kabob-headcount-silk.ngrok-free.dev/api";

// Pins
#define OLED_SDA 13
#define OLED_SCL 14

#define DHT_PIN 12
#define DHT_TYPE DHT11

#define SOIL_AO_PIN 10
#define SOIL_DO_PIN 11

#define WATER_SENSOR_PIN 9

#define PUMP_RELAY_PIN 3
#define LIGHT_PIN 38

// Relay logic
#define RELAY_ON LOW
#define RELAY_OFF HIGH

DHT dht(DHT_PIN, DHT_TYPE);

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

unsigned long lastSensorSend = 0;
unsigned long lastCommandFetch = 0;
unsigned long lastHeartbeat = 0;
unsigned long lastDisplayChange = 0;

const unsigned long SENSOR_INTERVAL = 5000;
const unsigned long COMMAND_INTERVAL = 3000;
const unsigned long HEARTBEAT_INTERVAL = 10000;
const unsigned long DISPLAY_INTERVAL = 5000;

int displayPage = 0;

float temperature = 0;
float humidity = 0;
int soilPercent = 0;
bool waterDetected = true;

bool pumpOn = false;
bool lightOn = false;

int readSoilMoisturePercent() {
  int raw = analogRead(SOIL_AO_PIN);

  // Ezt majd kalibrálni kell:
  // száraz érték és vizes érték szenzortól függ.
  int dryValue = 4095;
  int wetValue = 1200;

  int percent = map(raw, dryValue, wetValue, 0, 100);
  percent = constrain(percent, 0, 100);

  return percent;
}

void setPump(bool state) {
  pumpOn = state;
  digitalWrite(PUMP_RELAY_PIN, state ? RELAY_ON : RELAY_OFF);
}

void setLight(bool state) {
  lightOn = state;
  digitalWrite(LIGHT_PIN, state ? HIGH : LOW);
}

void readSensors() {
  float t = dht.readTemperature();
  float h = dht.readHumidity();

  if (!isnan(t)) temperature = t;
  if (!isnan(h)) humidity = h;

  soilPercent = readSoilMoisturePercent();

  // Szenzortól függően lehet fordítva is.
  waterDetected = digitalRead(WATER_SENSOR_PIN) == HIGH;
}

void sendSensorData() {
  if (WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;
  String url = String(API_BASE_URL) + "/sensors";

  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("ngrok-skip-browser-warning", "true");

  StaticJsonDocument<256> doc;
  doc["temperature"] = temperature;
  doc["humidity"] = humidity;
  doc["soilMoisture"] = soilPercent;
  doc["waterDetected"] = waterDetected;
  doc["lightOn"] = lightOn;
  doc["pumpOn"] = pumpOn;

  String body;
  serializeJson(doc, body);

  int code = http.POST(body);

  Serial.print("POST /sensors: ");
  Serial.println(code);

  http.end();
}

void fetchCommands() {
  if (WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;
  String url = String(API_BASE_URL) + "/esp32/commands";

  http.begin(url);
  http.addHeader("ngrok-skip-browser-warning", "true");

  int code = http.GET();

  Serial.print("GET /esp32/commands: ");
  Serial.println(code);

  if (code == 200) {
    String payload = http.getString();

    StaticJsonDocument<256> doc;
    DeserializationError error = deserializeJson(doc, payload);

    if (!error) {
      bool commandPump = doc["pump"] | false;
      bool commandLight = doc["light"] | false;

      if (!waterDetected && commandPump) {
        setPump(false);
      } else {
        setPump(commandPump);
      }

      setLight(commandLight);
    }
  }

  http.end();
}

void sendHeartbeat() {
  if (WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;
  String url = String(API_BASE_URL) + "/esp32/heartbeat";

  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("ngrok-skip-browser-warning", "true");

  StaticJsonDocument<256> doc;
  doc["wifiConnected"] = WiFi.status() == WL_CONNECTED;
  doc["mqttConnected"] = false;
  doc["signalStrength"] = map(WiFi.RSSI(), -90, -30, 0, 100);
  doc["freeRam"] = ESP.getFreeHeap() / 1024;
  doc["totalRam"] = 320;
  doc["cpuTemp"] = 0;
  doc["uptimeSeconds"] = millis() / 1000;
  doc["ipAddress"] = WiFi.localIP().toString();
  doc["firmwareVersion"] = "v1.0.0";

  String body;
  serializeJson(doc, body);

  int code = http.POST(body);

  Serial.print("POST /esp32/heartbeat: ");
  Serial.println(code);

  http.end();
}

void drawDisplay() {
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);

  display.setTextSize(1);
  display.setCursor(0, 0);
  display.println("Smart Greenhouse");

  display.setCursor(0, 12);

  if (displayPage == 0) {
    display.print("Temp: ");
    display.print(temperature, 1);
    display.println(" C");

    display.print("Hum:  ");
    display.print(humidity, 0);
    display.println(" %");

    display.print("Soil: ");
    display.print(soilPercent);
    display.println(" %");
  } else {
    display.print("Water: ");
    display.println(waterDetected ? "OK" : "EMPTY");

    display.print("Pump:  ");
    display.println(pumpOn ? "ON" : "OFF");

    display.print("Light: ");
    display.println(lightOn ? "ON" : "OFF");

    display.print("WiFi: ");
    display.println(WiFi.status() == WL_CONNECTED ? "OK" : "NO");
  }

  display.display();
}

void connectWiFi() {
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  Serial.print("Connecting WiFi");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();
  Serial.print("WiFi connected: ");
  Serial.println(WiFi.localIP());
}

void setup() {
  Serial.begin(115200);

  pinMode(SOIL_DO_PIN, INPUT);
  pinMode(WATER_SENSOR_PIN, INPUT);

  pinMode(PUMP_RELAY_PIN, OUTPUT);
  pinMode(LIGHT_PIN, OUTPUT);

  setPump(false);
  setLight(false);

  dht.begin();

  Wire.begin(OLED_SDA, OLED_SCL);

  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("OLED init failed");
  } else {
    display.clearDisplay();
    display.display();
  }

  connectWiFi();

  readSensors();
  drawDisplay();
}

void loop() {
  unsigned long now = millis();

  if (now - lastSensorSend >= SENSOR_INTERVAL) {
    lastSensorSend = now;
    readSensors();
    sendSensorData();
  }

  if (now - lastCommandFetch >= COMMAND_INTERVAL) {
    lastCommandFetch = now;
    fetchCommands();
  }

  if (now - lastHeartbeat >= HEARTBEAT_INTERVAL) {
    lastHeartbeat = now;
    sendHeartbeat();
  }

  if (now - lastDisplayChange >= DISPLAY_INTERVAL) {
    lastDisplayChange = now;
    displayPage = (displayPage + 1) % 2;
    drawDisplay();
  }
}