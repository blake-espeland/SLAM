#pragma once

#include "pixel.h"
#include "edge_detect.h"

#ifndef GPU
#include <opencv2/core.hpp>
#endif

#ifdef GPU
void flow_gpu(float* in, float* out, int b, int n);
void parse_gpu(float* in, float* out, int b, int n);
#endif



void edge(float* in, float* out);
void parse(float* in, float* out);