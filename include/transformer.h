#ifndef TRANSFORMER_H
#define TRANSFORMER_H
#include "tensor.h"

typedef struct{

} Transformer;


Transformer make_transformer_layer();
void transformer_forward(Tensor* X);
void transformer_backward();

#endif