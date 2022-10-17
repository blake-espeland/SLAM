#pragma once

typedef unsigned int channel_t;
typedef signed int channel_t_signed;

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