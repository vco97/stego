# A Python script to read a BMP image file, send its pixel data byte-by-byte
# over serial, and receive the encoded data back, saving it to a new file.
#
# This script is designed to work with an Arduino sketch that uses a
# synchronous "send one byte, receive one byte" protocol.

import serial
import time
import sys
import os

# Standard size for a BMP header in bytes
BMP_HEADER_SIZE = 138

def main():
    # Check for correct command-line arguments
    if len(sys.argv) != 3:
        print("Usage: python steganography_tester.py <image_path> <serial_port>")
        print("Example: python steganography_tester.py my_image.bmp COM3")
        print("Example: python steganography_tester.py my_image.bmp /dev/ttyACM0")
        return

    image_path = sys.argv[1]
    serial_port = sys.argv[2]
    baud_rate = 115200
    
    # Validate the input image file
    if not os.path.exists(image_path):
        print(f"Error: The file '{image_path}' does not exist.")
        return

    # Create the output file path
    output_path = os.path.splitext(image_path)[0] + "_encoded.bmp"
    print(f"Output file will be saved as: '{output_path}'")

    # Open the serial port connection
    try:
        ser = serial.Serial(serial_port, baud_rate, timeout=1)
        time.sleep(2) # Allow time for the Arduino to reset after connecting
        print(f"Connected to {serial_port}")
    except serial.SerialException as e:
        print(f"Error opening serial port: {e}")
        return

    # Read the entire original image file in binary mode
    try:
        with open(image_path, 'rb') as f:
            image_data = f.read()
            print(f"Read {len(image_data)} bytes from '{image_path}'")
    except IOError as e:
        print(f"Error reading image file: {e}")
        ser.close()
        return

    # Separate the header and pixel data
    header_data = image_data[:BMP_HEADER_SIZE]
    pixel_data = image_data[BMP_HEADER_SIZE:]
    print(f"BMP header ({len(header_data)} bytes) separated.")
    
    encoded_pixel_data = bytearray()
    
    # Iterate through each pixel byte of the image data
    print("Starting byte-by-byte transfer of pixel data...")
    for i, original_byte in enumerate(pixel_data):
        try:
            # Send one byte to the Arduino
            ser.write(bytes([original_byte]))

            # Wait for one byte to be available in the receive buffer
            # It will take about 2.04ms (2 * 10 bits / 9800 baud) for the FPGA to process and
            # respond at 9800 baud and then it will take a further 0.09ms for the byte to be 
            # received at 115200 baud
            start_time = time.time()
            while ser.in_waiting < 1:
                # Implement a timeout in case of communication failure
                if (time.time() - start_time) > 1:  # 1 second timeout
                    raise serial.SerialTimeoutException("Timeout waiting for response from Arduino.")
                time.sleep(0.001) # Small delay to prevent busy-waiting

            # Wait for and read the single encoded byte response from the Arduino
            encoded_byte = ser.read(1)
            # print(f"\rTransferred byte {i+1}/{len(pixel_data)}", end='', flush=True)

            # Append the received byte to our encoded data bytearray
            encoded_pixel_data.extend(encoded_byte)
            # time.sleep(10)  # Small delay to avoid overwhelming the serial buffer

        except serial.SerialException as e:
            print(f"\nError during serial transfer at byte {i}: {e}")
            ser.close()
            return
            
    # Write the complete encoded data to the output file
    try:
        with open(output_path, 'wb') as f:
            f.write(header_data) # Write the original header first
            f.write(encoded_pixel_data) # Then write the encoded pixel data
        print(f"Transfer complete. Saved {len(header_data) + len(encoded_pixel_data)} bytes to '{output_path}'")
    except IOError as e:
        print(f"\nError saving output file: {e}")

    ser.close()
    print("Serial port closed.")

if __name__ == "__main__":
    main()