#pragma once
#define G_KERNEL_SIZE 7
#define MAX_THREADS 1024

#include "pixel.h"

#ifndef GPU
#include <opencv2/core.hpp>
#endif

#ifdef GPU
void flow_gpu(float* in, float* out, int b, int n);
void edge_gpu(pixel_t* in, channel_t* out, int b, int n);
void parse_gpu(float* in, float* out, int b, int n);
#endif



void edge(float* in, float* out);
void parse(float* in, float* out);