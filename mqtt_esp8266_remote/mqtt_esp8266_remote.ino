/***************************************************
  Adafruit MQTT Library ESP8266 Example

  Must use ESP8266 Arduino from:
    https://github.com/esp8266/Arduino

  Works great with Adafruit's Huzzah ESP board & Feather
  ----> https://www.adafruit.com/product/2471
  ----> https://www.adafruit.com/products/2821

  Adafruit invests time and resources providing this open source code,
  please support Adafruit and open-source hardware by purchasing
  products from Adafruit!

  Written by Tony DiCola for Adafruit Industries.
  MIT license, all text above must be included in any redistribution
 ****************************************************/
#include <ESP8266WiFi.h>
#include "Adafruit_MQTT.h"
#include "Adafruit_MQTT_Client.h"

// LED
#define PIN_LED_RED     14
#define PIN_LED_YELLOW  13
#define PIN_LED_GREEN   12

// button
#define GPIO_INTERRUPT_PIN 4
#define DEBOUNCE_TIME 200 
volatile unsigned long count_prev_time;
volatile unsigned long count;

ICACHE_RAM_ATTR void count_isr(){
  if (count_prev_time + DEBOUNCE_TIME < millis() || count_prev_time > millis()) {
    count_prev_time = millis(); 
    count++;
  }
}

/************************* WiFi Access Point *********************************/

#define WLAN_SSID       "EMLI_Team_15"
#define WLAN_PASS       "coolkids"

/****************************** MQTT Setup ***********************************/

#define AIO_SERVER      "10.42.0.1"
#define AIO_SERVERPORT  1883                   // use 8883 for SSL
#define AIO_USERNAME    "pi"
#define AIO_KEY         "raspberry"

#define MQTT_BASE_TOPIC  "dev0"
//#define MQTT_RED         "/led/red"
//#define MQTT_YELLOW      "/led/yellow"
//#define MQTT_GREEN       "/led/green"
//#define MQTT_BUTTON      "/led/button"
const char MQTT_RED[] = MQTT_BASE_TOPIC "/led/red";
const char MQTT_YELLOW[] = MQTT_BASE_TOPIC "/led/yellow";
const char MQTT_GREEN[] = MQTT_BASE_TOPIC "/led/green";
const char MQTT_BUTTON[] = MQTT_BASE_TOPIC "/button";

/************ Global State (you don't need to change this!) ******************/

// Create an ESP8266 WiFiClient class to connect to the MQTT server.
WiFiClient client;
// or... use WiFiClientSecure for SSL
//WiFiClientSecure client;

// Setup the MQTT client class by passing in the WiFi client and MQTT server and login details.
Adafruit_MQTT_Client mqtt(&client, AIO_SERVER, AIO_SERVERPORT, AIO_USERNAME, AIO_KEY);

/****************************** Feeds ***************************************/

// Setup a feed called 'photocell' for publishing.
Adafruit_MQTT_Publish button = Adafruit_MQTT_Publish(&mqtt, MQTT_BUTTON /*"pi/led/button"*/);

// Setup a feed called 'onoff' for subscribing to changes.
Adafruit_MQTT_Subscribe redLed = Adafruit_MQTT_Subscribe(&mqtt, MQTT_RED /*"pi/led/red"*/);
Adafruit_MQTT_Subscribe yellowLed = Adafruit_MQTT_Subscribe(&mqtt, MQTT_YELLOW/*"pi/led/yellow"*/);
Adafruit_MQTT_Subscribe greenLed = Adafruit_MQTT_Subscribe(&mqtt, MQTT_GREEN/*"pi/led/green"*/);

/*************************** Sketch Code ************************************/

// Bug workaround for Arduino 1.6.6, it seems to need a function declaration
// for some reason (only affects ESP8266, likely an arduino-builder bug).
void MQTT_connect();

//helper for changing led status
void pinChange(int pin, char * string){
  if(strcmp(string,"on")==0){
    digitalWrite(pin, HIGH);
  }else if(strcmp(string,"off")==0){
    digitalWrite(pin, LOW);
  }
}

void setup() {
  //led initialization
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);
  pinMode(PIN_LED_RED, OUTPUT);
  digitalWrite(PIN_LED_RED, LOW);
  pinMode(PIN_LED_YELLOW, OUTPUT);
  digitalWrite(PIN_LED_YELLOW, LOW);
  pinMode(PIN_LED_GREEN, OUTPUT);
  digitalWrite(PIN_LED_GREEN, LOW);

  Serial.begin(115200);
  delay(10);
  Serial.println(F("Adafruit MQTT demo"));

  // button
  count_prev_time = millis();
  count = 0;
  pinMode(GPIO_INTERRUPT_PIN, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(GPIO_INTERRUPT_PIN), count_isr, RISING);

  // Connect to WiFi access point.
  Serial.println(); Serial.println();
  Serial.print("Connecting to ");
  Serial.println(WLAN_SSID);

  WiFi.begin(WLAN_SSID, WLAN_PASS);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();

  Serial.println("WiFi connected");
  Serial.println("IP address: "); Serial.println(WiFi.localIP());

  // Setup MQTT subscription for onoff feed.
  mqtt.subscribe(&redLed);
  mqtt.subscribe(&yellowLed);
  mqtt.subscribe(&greenLed);
}

uint32_t x=0;

void loop() {
  // Ensure the connection to the MQTT server is alive (this will make the first
  // connection and automatically reconnect when disconnected).  See the MQTT_connect
  // function definition further below.
  MQTT_connect();

  // this is our 'wait for incoming subscription packets' busy subloop
  // try to spend your time here

  if (count!=0) {
    Serial.print(F("\nSending val "));
    Serial.print(count);
    if (! button.publish((int)count)) {
      Serial.println(F("Failed"));
    } else {
      Serial.println(F(" OK!"));
    }
    count = 0;
  }

  Adafruit_MQTT_Subscribe *subscription;
  while ((subscription = mqtt.readSubscription(5000))) {
    if (subscription == &redLed) {
      Serial.print(F("Got: "));
      Serial.println((char *)redLed.lastread);
      pinChange(PIN_LED_RED, (char *)redLed.lastread);
    }
    if (subscription == &yellowLed) {
      Serial.print(F("Got: "));
      Serial.println((char *)yellowLed.lastread);
      pinChange(PIN_LED_YELLOW, (char *)yellowLed.lastread);
    }
    if (subscription == &greenLed) {
      Serial.print(F("Got: "));
      Serial.println((char *)greenLed.lastread);
      pinChange(PIN_LED_GREEN, (char *)greenLed.lastread);
    }
  }

  // ping the server to keep the mqtt connection alive
  // NOT required if you are publishing once every KEEPALIVE seconds
  /*
  if(! mqtt.ping()) {
    mqtt.disconnect();
  }
  */
}

// Function to connect and reconnect as necessary to the MQTT server.
// Should be called in the loop function and it will take care if connecting.
void MQTT_connect() {
  int8_t ret;

  // Stop if already connected.
  if (mqtt.connected()) {
    return;
  }

  Serial.print("Connecting to MQTT... ");

  uint8_t retries = 3;
  while ((ret = mqtt.connect()) != 0) { // connect will return 0 for connected
       Serial.println(mqtt.connectErrorString(ret));
       Serial.println("Retrying MQTT connection in 5 seconds...");
       mqtt.disconnect();
       delay(5000);  // wait 5 seconds
       retries--;
       if (retries == 0) {
         // basically die and wait for WDT to reset me
         while (1);
       }
  }
  Serial.println("MQTT Connected!");
}
