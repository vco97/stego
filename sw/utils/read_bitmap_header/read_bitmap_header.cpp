#include <iostream>
#include <fstream>
#include <cstdint>

// A simple structure to represent the BITMAPFILEHEADER.
// The `__attribute__((packed))` is a GCC/Clang-specific extension to
// prevent the compiler from adding padding for alignment.
struct __attribute__((packed)) BitmapFileHeader {
    uint16_t bfType;       // Must be 0x4D42 ('BM')
    uint32_t bfSize;       // The size of the file in bytes
    uint16_t bfReserved1;  // Reserved, must be 0
    uint16_t bfReserved2;  // Reserved, must be 0
    uint32_t bfOffBits;    // The offset to the pixel data
};

void readBmpHeader(const char* filename) {
    std::ifstream file(filename, std::ios::binary);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open file " << filename << std::endl;
        return;
    }

    BitmapFileHeader header;
    file.read(reinterpret_cast<char*>(&header), sizeof(header));

    // Check the magic number to ensure it's a BMP file
    if (header.bfType != 0x4D42) {
        std::cerr << "Error: Not a valid BMP file." << std::endl;
        file.close();
        return;
    }

    std::cout << "File size: " << header.bfSize << " bytes" << std::endl;
    std::cout << "Header size (offset to pixel data): " << header.bfOffBits << " bytes" << std::endl;
    
    file.close();
}

int main() {
    // Example usage with a sample BMP file
    // Replace "sample_image.bmp" with your file path
    readBmpHeader("../../../data/images/test_10x10.bmp");
    return 0;
}