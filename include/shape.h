#ifndef SHAPE_H
#define SHAPE_H
#include <stdarg.h>
#include <stdlib.h>
#include <stdio.h>

typedef struct{
    uint* dims;
    size_t ndims;
    size_t size;
} shape;

shape* make_shape(size_t ndims, ...);
void free_shape(shape* shp);
void print_shape(shape* shp);

int compare_shapes(shape* s1, shape* s2);

#endif