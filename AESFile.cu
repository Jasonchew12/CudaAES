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

    const int bufferBlocks = 8192;  // Number of blocks to read into memory at once
    unsigned char* buffer = new unsigned char[bufferBlocks * blockSize];
    unsigned char* encrypted = new unsigned char[bufferBlocks * blockSize];

    // Allocate device memory
    unsigned char* d_input;
    unsigned char* d_output;
    unsigned char* d_expandedKey;

    // Set the number of rounds based on key size
    int nbrRounds;
    switch (size) {
    case SIZE_16: nbrRounds = 10; break;
    case SIZE_24: nbrRounds = 12; break;
    case SIZE_32: nbrRounds = 14; break;
    default: return false;
    }


    cudaMalloc((void**)&d_input, bufferBlocks * blockSize * sizeof(unsigned char));
    cudaMalloc((void**)&d_output, bufferBlocks * blockSize * sizeof(unsigned char));
    cudaMalloc((void**)&d_expandedKey, 240);  // Expanded key size for AES-256 is 240 bytes (14 rounds)

    // Expand the key on the host (assuming you have an ExpandKey function)
    unsigned char expandedKey[240];
    CreateExpandKey(expandedKey, key, size, (nbrRounds + 1) * blockSize);
    cudaMemcpy(d_expandedKey, expandedKey, 240, cudaMemcpyHostToDevice);

    while (input.read(reinterpret_cast<char*>(buffer), bufferBlocks * blockSize) || input.gcount() > 0) {
        std::streamsize bytesRead = input.gcount();
        int blocksRead = static_cast<int>(bytesRead / blockSize);

        // Handle any partial blocks by padding
        if (bytesRead % blockSize != 0) {
            std::memset(buffer + bytesRead, 0, (blockSize - (bytesRead % blockSize)));
            blocksRead++;
        }

        // Copy data to device
        cudaMemcpy(d_input, buffer, blocksRead * blockSize, cudaMemcpyHostToDevice);

        // Launch CUDA kernel
        int threadsPerBlock = 256;  // Adjust depending on GPU capabilities
        int numBlocks = (blocksRead + threadsPerBlock - 1) / threadsPerBlock;
        AES_EncryptKernel << <numBlocks, threadsPerBlock >> > (d_input, d_output, d_expandedKey, blocksRead, 14);

        // Wait for the GPU to finish
        cudaDeviceSynchronize();

        // Copy encrypted data back to host
        cudaMemcpy(encrypted, d_output, blocksRead * blockSize, cudaMemcpyDeviceToHost);

        // Write the encrypted blocks to the output file
        output.write(reinterpret_cast<char*>(encrypted), blocksRead * blockSize);
    }

    // Cleanup
    input.close();
    output.close();
    delete[] buffer;
    delete[] encrypted;
    cudaFree(d_input);
    cudaFree(d_output);
    cudaFree(d_expandedKey);

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

    const int bufferBlocks = 8192;  // Number of blocks to read into memory at once
    unsigned char* buffer = new unsigned char[bufferBlocks * blockSize];
    unsigned char* decrypted = new unsigned char[bufferBlocks * blockSize];

    // Allocate device memory
    unsigned char* d_input;
    unsigned char* d_output;
    unsigned char* d_expandedKey;

    int nbrRounds;
    switch (size) {
    case SIZE_16: nbrRounds = 10; break;
    case SIZE_24: nbrRounds = 12; break;
    case SIZE_32: nbrRounds = 14; break;
    default: return false;
    }

    cudaMalloc((void**)&d_input, bufferBlocks * blockSize * sizeof(unsigned char));
    cudaMalloc((void**)&d_output, bufferBlocks * blockSize * sizeof(unsigned char));
    cudaMalloc((void**)&d_expandedKey, 240);  // Expanded key size for AES-256 is 240 bytes (14 rounds)

    // Expand the key on the host (assuming you have an ExpandKey function)
    unsigned char expandedKey[240];
    CreateExpandKey(expandedKey, key, size, (nbrRounds + 1) * blockSize);
    cudaMemcpy(d_expandedKey, expandedKey, 240, cudaMemcpyHostToDevice);

    while (input.read(reinterpret_cast<char*>(buffer), bufferBlocks * blockSize) || input.gcount() > 0) {
        std::streamsize bytesRead = input.gcount();
        int blocksRead = static_cast<int>(bytesRead / blockSize);

        // Handle any partial blocks by padding
        if (bytesRead % blockSize != 0) {
            std::memset(buffer + bytesRead, 0, (blockSize - (bytesRead % blockSize)));
            blocksRead++;
        }

        // Copy data to device
        cudaMemcpy(d_input, buffer, blocksRead * blockSize, cudaMemcpyHostToDevice);

        // Launch CUDA decryption kernel
        int threadsPerBlock = 256;  // Adjust depending on GPU capabilities
        int numBlocks = (blocksRead + threadsPerBlock - 1) / threadsPerBlock;
        AES_DecryptKernel << <numBlocks, threadsPerBlock >> > (d_input, d_output, d_expandedKey, blocksRead, 14);

        // Wait for the GPU to finish
        cudaDeviceSynchronize();

        // Copy decrypted data back to host
        cudaMemcpy(decrypted, d_output, blocksRead * blockSize, cudaMemcpyDeviceToHost);

        // Write the decrypted blocks to the output file
        output.write(reinterpret_cast<char*>(decrypted), blocksRead * blockSize);
    }

    // Cleanup
    input.close();
    output.close();
    delete[] buffer;
    delete[] decrypted;
    cudaFree(d_input);
    cudaFree(d_output);
    cudaFree(d_expandedKey);

    return true;
}


