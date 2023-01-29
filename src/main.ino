#include "pin_config.h";
#include "secrets.h";
#include <ESP8266WiFi.h>
#include <MQTT.h>
#include <MQTTClient.h>

// 00 10 [11] 01
enum ENCODER_STATE {
  IDLE, // 11

  CW_1, // 01
  CW_2, // 00
  CW_3, // 10,

  CCW_1, // 10
  CCW_2, // 00
  CCW_3, // 01
};
static enum ENCODER_STATE encoder_state = IDLE;
unsigned long last_sw_trigger_time;
unsigned long last_encoder_trigger_time;
unsigned long last_publish_time;
const int btn_debounce_delay = 250;
const int publish_debounce_delay = 250;
int delta = 0;
int brightness = 0;
const int factor = 10;

const char ssid[] = WIFI_SSID;
const char pass[] = WIFI_PASS;

WiFiClient net;
MQTTClient client;

void connect() {
  Serial.print("checking wifi...");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(1000);
  }

  Serial.print("\nconnecting...");
  while (!client.connect("knoblight", HA_USER, HA_PASS)) {
    Serial.print(".");
    delay(1000);
  }

  Serial.println("\nconnected!");

  client.subscribe("knoblight/brightness");
}

void cw_callback() {
  last_encoder_trigger_time = millis();
  Serial.println("CW");
  delta++;
}

void ccw_callback() {
  last_encoder_trigger_time = millis();
  Serial.println("CCW");
  delta--;
}

void sw_callback() {
  if ((millis() - last_sw_trigger_time) > btn_debounce_delay) {
    last_sw_trigger_time = millis();
    Serial.println("SW");
    client.publish("knoblight/btn", "1");
  }
}

void IRAM_ATTR encoder_ISR() {
  uint8 clk = digitalRead(PIN_ENC_CLK);
  uint8 dt = digitalRead(PIN_ENC_DT);

  switch (encoder_state) {
  case IDLE: {
    if (!clk && dt) {
      encoder_state = CW_1;
    } else if (clk && !dt) {
      encoder_state = CCW_1;
    }
    break;
  }

  case CW_1: {
    if (!clk && !dt) {
      encoder_state = CW_2;
    } else if (clk && dt) {
      encoder_state = IDLE;
    }
    break;
  }

  case CW_2: {
    if (clk && !dt) {
      encoder_state = CW_3;
    } else if (clk && dt) {
      encoder_state = IDLE;
    }
    break;
  }

  case CW_3: {
    if (clk && dt) {
      encoder_state = IDLE;
      cw_callback();
    }
    break;
  }

  case CCW_1: {
    if (!clk && !dt) {
      encoder_state = CCW_2;
    } else if (clk && dt) {
      encoder_state = IDLE;
    }
    break;
  }

  case CCW_2: {
    if (!clk && dt) {
      encoder_state = CCW_3;
    } else if (clk && dt) {
      encoder_state = IDLE;
    }
    break;
  }

  case CCW_3: {
    if (clk && dt) {
      encoder_state = IDLE;
      ccw_callback();
    }
    break;
  }
  }
}

void IRAM_ATTR button_ISR() {
  sw_callback();
}

void messageReceived(String &topic, String &payload) {
  Serial.println("incoming: " + topic + " - " + payload);

  if (topic == "knoblight/brightness") {
    brightness = atoi(payload.c_str());
  }
}

void publish() {
  brightness = brightness + delta * factor;
  if (brightness > 255) {
    brightness = 255;
  } else if (brightness < 0) {
    brightness = 0;
  }
  delta = 0;
  client.publish("knoblight/brightness/set", String(brightness));
  Serial.print("Sending brightness ");
  Serial.println(String(brightness));
}

void setup() {
  Serial.begin(115200);

  last_sw_trigger_time = millis();

  pinMode(PIN_ENC_CLK, INPUT_PULLUP);
  pinMode(PIN_ENC_DT, INPUT_PULLUP);
  pinMode(PIN_ENC_SW, INPUT_PULLUP);

  attachInterrupt(digitalPinToInterrupt(PIN_ENC_CLK), encoder_ISR, CHANGE);
  attachInterrupt(digitalPinToInterrupt(PIN_ENC_DT), encoder_ISR, CHANGE);
  attachInterrupt(digitalPinToInterrupt(PIN_ENC_SW), button_ISR, FALLING);

  WiFi.begin(ssid, pass);

  client.begin(BROKER_IP, net);

  client.onMessage(messageReceived);

  delay(1000);
  connect();
}

void loop() {
  client.loop();
  delay(10); // <- fixes some issues with WiFi stability

  if (!client.connected()) {
    connect();
  }

  if (delta != 0 && millis() - last_encoder_trigger_time > publish_debounce_delay) {
    publish();
  }
}