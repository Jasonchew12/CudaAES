// main.cpp
#include "AES.cuh"

#include <chrono>
#include <cstdlib>

void DisplayAESExplanationkey(unsigned char* key, enum keySize size)
{
    const int expandedKeySizeDisplay = 240;

    // the expanded key
    unsigned char expandedKeyDisplay[expandedKeySizeDisplay];


    CreateExpandKey(expandedKeyDisplay, key, size, expandedKeySizeDisplay);

    std::cout << "Expanded Key:\n";
    for (int i = 0; i < expandedKeySizeDisplay; i++) {
        // Print the block number at the beginning of each new line
        if (i % 16 == 0) {
            std::cout << (i / 16 + 1) << ": ";  // Block number starts from 1
        }

        std::cout << std::hex << std::setw(2) << std::setfill('0')
            << static_cast<int>(expandedKeyDisplay[i]);

        // Insert a space after each byte for readability
        if ((i + 1) % 16 == 0) {
            std::cout << std::endl;  // Print a newline after every 16 bytes
        }
        else {
            std::cout << " ";  // Print a space otherwise
        }
    }

}

#pragma region CUDAFILEVersion
int main(int argc, char* argv[])
{
    // Define file paths for input and output
    //std::string inputFilePath = "FileToEncrypt/500mb-examplefile-com.txt";
    //           // Input file to encrypt
    std::string inputFilePath = "FileToEncrypt/500mb.txt";           // Input file to encrypt
    std::string encryptedFilePath = "EncryptFile/500mbEncryptedCUDA.bin"; // Encrypted output file
    std::string decryptedFilePath = "DecryptFile/500mb_unencrypted.txt"; // Decrypted output file

    // Define the key and key size (256-bit in this example)
    unsigned char key[32] = { "HalloWorldThisIsAStringOfLetter" }; // Example key
    enum keySize size = SIZE_32;  // You can change this to SIZE_16 or SIZE_24 for 128-bit or 192-bit keys

    // Display the expanded key for informational purposes
    DisplayAESExplanationkey(key, size);

    // Measure encryption time
    auto encryptionStart = std::chrono::high_resolution_clock::now();

    // Encrypt the file
    if (EncryptFile(inputFilePath, encryptedFilePath, key, size)) {
        std::cout << "File encryption completed successfully!" << std::endl;
    }
    else {
        std::cerr << "File encryption failed!" << std::endl;
        return -1;
    }

    auto encryptionEnd = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> encryptionDuration = encryptionEnd - encryptionStart;
    std::cout << "Time taken for encryption: " << encryptionDuration.count() << " seconds" << std::endl;

    // Measure decryption time
    auto decryptionStart = std::chrono::high_resolution_clock::now();

    // Decrypt the file
    if (DecryptFile(encryptedFilePath, decryptedFilePath, key, size)) {
        std::cout << "File decryption completed successfully!" << std::endl;
    }
    else {
        std::cerr << "File decryption failed!" << std::endl;
        return -1;
    }

    auto decryptionEnd = std::chrono::high_resolution_clock::now();
    std::chrono::duration<double> decryptionDuration = decryptionEnd - decryptionStart;
    std::cout << "Time taken for decryption: " << decryptionDuration.count() << " seconds" << std::endl;

    // Optionally, you can open the original and decrypted files for comparison
    std::string openOriginalFileCommand = "start " + inputFilePath;
    system(openOriginalFileCommand.c_str());

    std::string openDecryptedFileCommand = "start " + decryptedFilePath;
    system(openDecryptedFileCommand.c_str());

    return 0;
}
#pragma endregion

#pragma region CUDASmallAES
//int main() {
//    // Define a small input message (exactly 16 bytes, no padding required)
//    const char* testInput = "abcdef1234567890";  // 16 bytes (exactly one AES block)
//    unsigned char encrypted[16];
//    unsigned char decrypted[16];
//    
//    // AES key (this should match the key size you're using in the real test)
//    unsigned char key[32] = { "Hallo World" };  // Example key, AES-256 (32 bytes)
//
//    // Print the original message
//    std::cout << "Original message: " << testInput << std::endl;
//
//    // Encrypt the message
//    char resultEncrypt = AES_Encrypt((unsigned char*)testInput, encrypted, key, SIZE_32);
//    if (resultEncrypt != SUCCESS) {
//        std::cerr << "Encryption failed with error code: " << resultEncrypt << std::endl;
//        return -1;
//    }
//
//    // Print encrypted message in hex
//    std::cout << "Encrypted message (hex): ";
//    for (int i = 0; i < 16; ++i) {
//        std::cout << std::hex << (int)encrypted[i] << " ";
//    }
//    std::cout << std::endl;
//
//    // Decrypt the message
//    char resultDecrypt = AES_Decrypt(encrypted, decrypted, key, SIZE_32);
//    if (resultDecrypt != SUCCESS) {
//        std::cerr << "Decryption failed with error code: " << resultDecrypt << std::endl;
//        return -1;
//    }
//
//    // Print the decrypted message
//    std::cout << "Decrypted message: " << decrypted << std::endl;
//
//    // Compare original and decrypted message
//    if (std::memcmp(testInput, decrypted, 16) == 0) {
//        std::cout << "Decryption successful!" << std::endl;
//    } else {
//        std::cout << "Decryption failed. Original and decrypted message do not match." << std::endl;
//    }
//
//    return 0;
//}
#pragma endregion



