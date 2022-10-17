#pragma once
#include "pixel.h"
#define G_KERNEL_SIZE 7

void canny_gpu(channel_t *final_pixels, pixel_t *orig_pixels, int rows,
               int cols, double kernel[G_KERNEL_SIZE][G_KERNEL_SIZE]);