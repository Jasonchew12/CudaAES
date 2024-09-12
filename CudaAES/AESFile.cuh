
// AESFILE.cuh
#ifndef AESFILE_CUH
#define AESFILE_CUH

#include <fstream>
#include <cstring>
#include <string>
#include <cuda_runtime.h>
#include "AESCore.cuh"

bool EncryptFile(const std::string& inFile, const std::string& outFile, unsigned char* key, enum keySize size);
bool DecryptFile(const std::string& inFile, const std::string& outFile, unsigned char* key, enum keySize size);

#endif // AESFILE_CUH
