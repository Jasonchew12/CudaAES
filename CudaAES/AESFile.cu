#include "AESFile.cuh"
#include "AESCore.cuh"
#include "AES.cuh"


bool EncryptFile(const std::string& inFile, const std::string& outFile, unsigned char* key, enum keySize size) {
    const int blockSize = 16;  // AES block size is 128 bits (16 bytes)
    std::ifstream input(inFile, std::ios::binary);
    std::ofstream output(outFile, std::ios::binary);

    if (!input.is_open() || !output.is_open()) {
        std::cerr << "Failed to open files!" << std::endl;
        return false;
    }

    // Determine the size of the file and the number of blocks
    input.seekg(0, std::ios::end);
    size_t fileSize = input.tellg();
    input.seekg(0, std::ios::beg);
    int numBlocks = (fileSize + blockSize - 1) / blockSize;  // Rounds up

    // Allocate host memory for input and output
    unsigned char* h_input = new unsigned char[numBlocks * blockSize];
    unsigned char* h_output = new unsigned char[numBlocks * blockSize];

    // Read the input file into host memory
    input.read(reinterpret_cast<char*>(h_input), fileSize);
    input.close();

    // Padding the last block if necessary
    if (fileSize % blockSize != 0) {
        std::memset(h_input + fileSize, 0, numBlocks * blockSize - fileSize);
    }

    // Set the number of rounds based on key size
    int nbrRounds;
    switch (size) {
    case SIZE_16: nbrRounds = 10; break;
    case SIZE_24: nbrRounds = 12; break;
    case SIZE_32: nbrRounds = 14; break;
    default: return false;
    }

    // Allocate device memory
    unsigned char* d_input, * d_output, * d_expandedKey;
    cudaMalloc(&d_input, numBlocks * blockSize * sizeof(unsigned char));
    cudaMalloc(&d_output, numBlocks * blockSize * sizeof(unsigned char));
    cudaMalloc(&d_expandedKey, (nbrRounds + 1) * blockSize * sizeof(unsigned char));

    // Copy input data and expanded key to device
    cudaMemcpy(d_input, h_input, numBlocks * blockSize * sizeof(unsigned char), cudaMemcpyHostToDevice);

    unsigned char expandedKey[240];  // Maximum size for AES-256
    CreateExpandKey(expandedKey, key, size, (nbrRounds + 1) * blockSize);
    cudaMemcpy(d_expandedKey, expandedKey, (nbrRounds + 1) * blockSize * sizeof(unsigned char), cudaMemcpyHostToDevice);

    // Launch AES kernel
    int threadsPerBlock = 256;
    int blocksPerGrid = (numBlocks + threadsPerBlock - 1) / threadsPerBlock;
    AES_EncryptKernel << <blocksPerGrid, threadsPerBlock >> > (d_input, d_output, d_expandedKey, numBlocks, nbrRounds);

    // Copy the encrypted output back to host
    cudaMemcpy(h_output, d_output, numBlocks * blockSize * sizeof(unsigned char), cudaMemcpyDeviceToHost);

    // Write the output file
    output.write(reinterpret_cast<char*>(h_output), numBlocks * blockSize);
    output.close();

    // Free memory
    cudaFree(d_input);
    cudaFree(d_output);
    cudaFree(d_expandedKey);
    delete[] h_input;
    delete[] h_output;

    return true;
}

bool DecryptFile(const std::string& inFile, const std::string& outFile, unsigned char* key, enum keySize size) {
    const int blockSize = 16;  // AES block size is 128 bits (16 bytes)
    std::ifstream input(inFile, std::ios::binary);
    std::ofstream output(outFile, std::ios::binary);

    if (!input.is_open() || !output.is_open()) {
        std::cerr << "Failed to open files!" << std::endl;
        return false;
    }

    // Determine the size of the file and the number of blocks
    input.seekg(0, std::ios::end);
    size_t fileSize = input.tellg();
    input.seekg(0, std::ios::beg);
    int numBlocks = (fileSize + blockSize - 1) / blockSize;  // Rounds up

    // Allocate host memory for input and output
    unsigned char* h_input = new unsigned char[numBlocks * blockSize];
    unsigned char* h_output = new unsigned char[numBlocks * blockSize];

    // Read the input file into host memory
    input.read(reinterpret_cast<char*>(h_input), fileSize);
    input.close();

    // Set the number of rounds based on key size
    int nbrRounds;
    switch (size) {
    case SIZE_16: nbrRounds = 10; break;
    case SIZE_24: nbrRounds = 12; break;
    case SIZE_32: nbrRounds = 14; break;
    default: return false;
    }

    // Allocate device memory
    unsigned char* d_input, * d_output, * d_expandedKey;
    cudaMalloc(&d_input, numBlocks * blockSize * sizeof(unsigned char));
    cudaMalloc(&d_output, numBlocks * blockSize * sizeof(unsigned char));
    cudaMalloc(&d_expandedKey, (nbrRounds + 1) * blockSize * sizeof(unsigned char));

    // Copy input data and expanded key to device
    cudaMemcpy(d_input, h_input, numBlocks * blockSize * sizeof(unsigned char), cudaMemcpyHostToDevice);

    unsigned char expandedKey[240];  // Maximum size for AES-256
    CreateExpandKey(expandedKey, key, size, (nbrRounds + 1) * blockSize);
    cudaMemcpy(d_expandedKey, expandedKey, (nbrRounds + 1) * blockSize * sizeof(unsigned char), cudaMemcpyHostToDevice);

    // Launch AES decryption kernel
    int threadsPerBlock = 256;
    int blocksPerGrid = (numBlocks + threadsPerBlock - 1) / threadsPerBlock;
    AES_DecryptKernel << <blocksPerGrid, threadsPerBlock >> > (d_input, d_output, d_expandedKey, numBlocks, nbrRounds);

    // Copy the decrypted output back to host
    cudaMemcpy(h_output, d_output, numBlocks * blockSize * sizeof(unsigned char), cudaMemcpyDeviceToHost);

    // Write the output file
    output.write(reinterpret_cast<char*>(h_output), numBlocks * blockSize);
    output.close();

    // Free memory
    cudaFree(d_input);
    cudaFree(d_output);
    cudaFree(d_expandedKey);
    delete[] h_input;
    delete[] h_output;

    return true;
}


