#ifndef TENSOR_H
#define TENSOR_H

#include <stdio.h>
#include "shape.h"

#define TENSOR_CHECK(x)         \
    if(!x){                     \
        perror("Null Tensor");  \
        exit(1);                \
    }                           \

typedef struct{
    float* X;
    shape shp;
} Tensor;

void fill_tensor(Tensor* t, float val);

float* alloc_tensor(shape shp);
void free_tensor(Tensor* t);

Tensor eye(int size);

Tensor* add(Tensor* first, Tensor* second);
Tensor* mult(Tensor* first, Tensor* second);

Tensor* zeros(shape shp);
Tensor* ones(shape shp);

#endif