#pragma once
#include <bits/stdint-uintn.h>
#include <stdint.h>

typedef uint16_t channel_t;
typedef int16_t channel_t_signed;

struct pixel_t {
    channel_t r;
    channel_t g;
    channel_t b;

    bool operator==(const pixel_t &rhs) {
        return (r == rhs.r) && (g == rhs.g) && (b == rhs.b);
    }

    bool operator!=(const pixel_t &rhs) {
        return (r != rhs.r) || (g != rhs.g) || (b != rhs.b);
    }

    bool operator>(const pixel_t &rhs) {
        return (r > rhs.r) && (g > rhs.g) && (b > rhs.b);
    }

    bool operator>=(const pixel_t &rhs) {
        return (r >= rhs.r) && (g >= rhs.g) && (b >= rhs.b);
    }

    bool operator<(const pixel_t &rhs) {
        return (r < rhs.r) && (g < rhs.g) && (b < rhs.b);
    }

    bool operator<=(const pixel_t &rhs) {
        return (r <= rhs.r) && (g <= rhs.g) && (b <= rhs.b);
    }
};