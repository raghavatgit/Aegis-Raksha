#include <stdint.h>
#include <stdbool.h>

#define SLEEP_INTERVAL_SECONDS 30
#define ULP_RTC_SLOW_MEM 0x50000000

void configure_esp32_sleep_cycle(uint32_t duration_sec) {
    uint64_t sleep_time_us = (uint64_t)duration_sec * 1000000ULL;
    // Mock register configuration for light/deep sleep
    volatile uint32_t* rtc_cntl = (volatile uint32_t*)ULP_RTC_SLOW_MEM;
    *rtc_cntl = (uint32_t)(sleep_time_us & 0xFFFFFFFF);
}

void enter_standby_mode(void) {
    configure_esp32_sleep_cycle(SLEEP_INTERVAL_SECONDS);
}
