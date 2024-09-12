

#ifndef AESCORE_CUH
#define AESCORE_CUH

#include <iostream>
#include <cstddef>
#include <cuda_runtime.h>
#include <device_launch_parameters.h>
enum errorCode
{
    SUCCESS = 0,
    UNKNOWN_KEYSIZE,
    MEMORY_ALLOCATION_PROBLEM,
};

enum keySize {
    SIZE_16 = 16,
    SIZE_24 = 24,
    SIZE_32 = 32
};

// CUDA kernel for AES encryption
__global__ void AES_EncryptKernel(unsigned char* input, unsigned char* output, unsigned char* expandedKey, int numBlocks, int nbrRounds);
// CUDA kernel for AES decryption
__global__ void AES_DecryptKernel(unsigned char* input, unsigned char* output, unsigned char* expandedKey, int numBlocks, int nbrRounds);
__host__ __device__ void CreateExpandKey(unsigned char* expandedKey, unsigned char* key, enum keySize, size_t expandedKeySize);

// Implementation: AES Encryption
// Implementation: subBytes
__host__ __device__ void SubBytes(unsigned char* state);
// Implementation: shiftRows
__host__ __device__ void ShiftRows(unsigned char* state);
__host__ __device__  void ShiftRow(unsigned char* state, unsigned char nbr);
// Implementation: addRoundKey
__host__ __device__ void AddRoundKey(unsigned char* state, unsigned char* roundKey);
// Implementation: mixColumns
unsigned char Galois_Multiplication(unsigned char a, unsigned char b);
__host__ __device__ void MixColumns(unsigned char* state);
__host__ __device__  void MixColumn(unsigned char* column);

// Implementation: AES Decryption
// Implementation: Inverse Sub Bytes
__host__ __device__ void InvSubBytes(unsigned char* state);
// Implementation: Inverse Shift Row
__host__ __device__ void InvShiftRows(unsigned char* state);
__host__ __device__ void InvShiftRow(unsigned char* state, unsigned char nbr);
// Implementation: Inverse MixColumn
__host__ __device__ void InvMixColumns(unsigned char* state);
__host__ __device__ void InvMixColumn(unsigned char* column);


// Implementation: AES round
__host__ __device__  void AES_Round(unsigned char* state, unsigned char* roundKey);
__host__ __device__ void AES_InvRound(unsigned char* state, unsigned char* roundKey);
__host__ __device__ void CreateRoundKey(unsigned char* expandedKey, unsigned char* roundKey);
__host__ __device__  void AES_Main(unsigned char* state, unsigned char* expandedKey, int nbrRounds);
__host__ __device__ void AES_InvMain(unsigned char* state, unsigned char* expandedKey, int nbrRounds);

__host__ __device__ char AES_Encrypt(unsigned char* input, unsigned char* output, unsigned char* key, enum keySize size);
__host__ __device__ char AES_Decrypt(unsigned char* input, unsigned char* output, unsigned char* key, enum keySize size);
#endif 