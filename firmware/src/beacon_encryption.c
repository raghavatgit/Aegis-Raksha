#include <stdint.h>
#include <string.h>

void xor_stream_cipher(const uint8_t* key, size_t key_len, uint32_t nonce, uint8_t* buffer, size_t buffer_len) {
    uint8_t state = (uint8_t)(nonce & 0xFF);
    for (size_t i = 0; i < buffer_len; i++) {
        uint8_t k = key[i % key_len] ^ state;
        buffer[i] ^= k;
        state = (state * 31) + 17;
    }
}
