#include <SoftwareSerial.h>

// Create a virtual serial port on pins 2 (RX) and 3 (TX)
// Connect the FPGA's TX to Arduino pin 2
// Connect the FPGA's RX to Arduino pin 3
SoftwareSerial FpgaSerial(2, 3); 

// Define a timeout for receiving data from the FPGA in milliseconds
#define TIMEOUT_MS 25 // A small, reasonable value for 9600 baud

void setup() {
    // Start serial communication at 9600 baud for communication with the computer
    Serial.begin(115200);
    // Wait for the serial port to connect. Needed for native USB port
    while (!Serial) { ; }

    // Start serial communication at 9600 baud with the FPGA
    FpgaSerial.begin(9800);
    Serial.println("Arduino ready. Now listening for image data from the computer.");
}

void loop() {
    // Check if a byte is available from the computer (via USB Serial)
    if (Serial.available() > 0) {
        // Read the incoming byte
        byte originalByte = Serial.read();

        // Immediately forward the byte to the FPGA module (via hardware Serial1)
        // This will take about 10 bits / 9800 baud = 1.02 ms
        FpgaSerial.write(originalByte);

        // Record the start time for the timeout
        unsigned long startTime = millis();
        bool receivedData = false;
        byte encodedByte;

        // Non-blocking loop with a timeout
        while (millis() - startTime < TIMEOUT_MS) {
            if (FpgaSerial.available() > 0) {
                // This will take about 10 bits / 9800 baud = 1.02 ms
                encodedByte = FpgaSerial.read();
                receivedData = true;
                break; // Exit the loop as soon as data is received
            }
        }
        
        if (receivedData) {
            // Forward the encoded byte to the computer
            Serial.write(encodedByte);
        } else {
            // This happens if the FPGA didn't respond in time.
            // Serial.println("Error: Timeout waiting for response from FPGA. Skipping byte.");
            Serial.write(0); // TODO: figure out how to communicate error; for now, put placeholder data
        }
    }
}

