#include "tensor.h"
#include "shape.h"
#include "tools.h"

#include <stdlib.h>
#include <string.h>

void fill_tensor(Tensor *t, float val){
    if (!t){
        perror("Null Tensor detected.");
        exit(1);
    }
    for (size_t i = 0; i < t->shape->size; ++i) t->X[i] = val; 
}

Tensor* add(Tensor* first, Tensor* second){
    if(!compare_shapes(first->shape, second->shape)){
        perror("Tensors must be same shape when adding.");
        exit(1);
    }
    Tensor* res = alloc_tensor(first->shape);

    for (int i = 0; i < first->shape->size; ++i)
        res->X[i] = first->X[i] + second->X[i];
    return res;
}

Tensor* vec_mat_prod(Tensor* vect, Tensor* mat){
    if (vect->shape->dims[1] != mat->shape->dims[0]){
        printf("Shapes don't agree for vector matrix product\n");
        print_shape(vect->shape);
        print_shape(mat->shape);
        exit(1);
    }

    shape* out_shape = make_shape(2, 1, mat->shape->dims[1]);   
    Tensor* res = alloc_tensor(out_shape);

    //TODO -> implement vect-mat product

    return res;
}

Tensor* mat_vec_prod(Tensor* vect, Tensor* mat){
    if (vect->shape->dims[1] != mat->shape->dims[0]){
        printf("Shapes don't agree for vector matrix product\n");
        print_shape(vect->shape);
        print_shape(mat->shape);
        exit(1);
    }

    shape* out_shape = make_shape(2, 1, mat->shape->dims[1]);   
    Tensor* res = alloc_tensor(out_shape);

    //TODO -> implement vect-mat product

    return res;
}

void scalar_mult(float a, Tensor* t){
    for (int i = 0; i < t->shape->size; ++i)
        t->X[i] *= a;
}

Tensor* mult(Tensor* first, Tensor* second){
    if (first->shape->ndims < 1 || second->shape->ndims < 1){
        perror("Illegal tensor shape(s) for multiplicaion.");
        print_shape(first->shape);
        print_shape(second->shape);
        exit(1);   
    }

    int fcolvect = first->shape->dims[1] == 1;
    int scolvect = second->shape->dims[1] == 1;
    int frowvect = first->shape->dims[0] == 1;
    int srowvect = second->shape->dims[0] == 1;

    if (frowvect && scolvect){
        return dot(first, second);
    }
    if (fcolvect && srowvect){
        return outer(first, second);
    }
    return NULL;
}

Tensor* cat(Tensor* first, Tensor* second, int dim){
    if( dim < 0 || dim > first->shape->ndims || dim > second->shape->ndims ){
        perror("Illegal dimension selected.");
        exit(1);
    }
    if ( second->shape->ndims != first->shape->ndims ){
        perror("Tensors must have same dimensionality.");
        exit(1);
    }
    for (int i = 0; i < first->shape->ndims; ++i){
        if (i != dim && first->shape->dims[i] != second->shape->dims[i]){
            perror("Tensors must have equivalent shapes in all other dimensions.");
            exit(1);
        }
    }

    size_t new_size = (first->shape->size + second->shape->size) * sizeof(float);
    Tensor* res = malloc(sizeof(Tensor));
    res->X = malloc(new_size);
    res->shape = cat_shapes(first->shape, second->shape, dim);

    
}


/* Tensor memory functions */

Tensor* alloc_tensor(shape* shape){
    if (!shape->dims){
        perror("Illegal shape.");
        exit(1);
    }

    Tensor* t = malloc(sizeof(Tensor));
    t->X = (float*)malloc(shape->size);
    t->shape = shape;

    return t;
}

void free_tensor(Tensor *t){
    free(t->X);
    free_shape(t->shape);
}

