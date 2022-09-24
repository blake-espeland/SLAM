#include "shape.h"


shape* make_shape(size_t ndims, ...){
    va_list valist;
    shape* s = malloc(sizeof(shape));

    s->ndims = ndims;
    s->dims = malloc(sizeof(size_t) * ndims);

    va_start(valist, ndims);

    int size = 1;
    int dim = 0;
    for (int i = 0; i < ndims; i++) {
      dim = va_arg(valist, size_t);
      size *= dim;
      s->dims[i] = dim;
    }
    s->size = size;

    va_end(valist);

    return s;
}

void print_shape(shape *shp){
    printf("shape size %ld: ", shp->size);
    printf("{");
    for (int i = 0; i < shp->ndims; i++){
        printf("%d, ", shp->dims[i]);
    }
    printf("}\n");
}

void free_shape(shape *shp){
    free(shp->dims);
    free(shp);
}

int compare_shapes(shape *s1, shape *s2){
    if (s1->ndims != s2->ndims) return 0;
    if (s1->size != s2->size) return 0;

    for (int i = 0; i < s1->ndims; ++i)
        if (s1->dims[i] != s2->dims[i]) return 0;
        
    return 1;
}