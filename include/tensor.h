#ifndef TENSOR_H
#define TENSOR_H

#include <stdio.h>
#include "shape.h"

typedef struct{
    float* X;
    shape* shape;
} Tensor;

void fill_tensor(Tensor* t, float val);
void scalar_mult(float a, Tensor* t);

Tensor* alloc_tensor(shape* shp);
void free_tensor(Tensor* t);

Tensor eye(int size);

Tensor* add(Tensor* first, Tensor* second);
Tensor* mult(Tensor* first, Tensor* second);
Tensor* T(Tensor* t);
Tensor* dot(Tensor* first, Tensor* second);
Tensor* outer(Tensor* first, Tensor* second);

Tensor* zeros(shape shp);
Tensor* ones(shape shp);

#endif