#include "shape.h"
#include "stdio.h"
#include "tensor.h"
#include "tools.h"

int main(){
    shape* t1_shp = make_shape(3, 99, 99, 99);
    print_shape(t1_shp);

    Tensor* t1 = alloc_tensor(t1_shp);
    printf("Tensor allocated\n");
    fill_tensor(t1, 6.9);
    printf("t1 at [0][0][2]: %f\n", t1->X[2]);
    
    free_tensor(t1);
    printf("Tensor freed\n");
}