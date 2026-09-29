#include <stdint.h>

#define ADC_REF_MV 3300
#define ADC_RESOLUTION 4096

uint16_t read_battery_millivolts(uint16_t raw_adc) {
    // Voltage divider with R1=100k, R2=100k (2:1 ratio)
    uint32_t mv = ((uint32_t)raw_adc * ADC_REF_MV * 2) / ADC_RESOLUTION;
    return (uint16_t)mv;
}

uint8_t calculate_state_of_charge(uint16_t battery_mv) {
    if (battery_mv >= 3350) return 100;
    if (battery_mv >= 3300) return 90;
    if (battery_mv >= 3250) return 70;
    if (battery_mv >= 3200) return 40;
    if (battery_mv >= 3000) return 10;
    return 0;
}
