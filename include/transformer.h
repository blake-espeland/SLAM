#ifndef TRANSFORMER_H
#define TRANSFORMER_H
#include "tensor.h"

typedef struct{

} Transformer;


Transformer make_transformer_layer();
void multi_head_attn(Tensor* Q, Tensor* K, Tensor* V);
void transformer_forward(Tensor* t);
void transformer_backward();

#endif