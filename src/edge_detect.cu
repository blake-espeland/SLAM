#include "feature_extract.h"
#include "pixel.h"

#include <vector>
#include <math.h>

#define _USE_MATH_DEFINES
#define RGB2GRAY_CONST_ARR_SIZE 3
#define STRONG_EDGE 0xFFFF
#define NON_EDGE 0x0

//*****************************************************************************************
// CUDA Gaussian Filter Implementation
//*****************************************************************************************

///
/// \brief Apply gaussian filter. This is the CUDA kernel for applying a gaussian blur to an image.
///
__global__
void apply_gaussian_filter_gpu(pixel_t *in_pixels, pixel_t *out_pixels, int rows, int cols, double *in_kernel)
{
    //copy kernel array from global memory to a shared array
    __shared__ double kernel[G_KERNEL_SIZE][G_KERNEL_SIZE];
    for (int i = 0; i < G_KERNEL_SIZE; ++i) {
        for (int j = 0; j < G_KERNEL_SIZE; ++j) {
            kernel[i][j] = in_kernel[i * G_KERNEL_SIZE + j];
        }
    }
    
    __syncthreads();

    //determine id of thread which corresponds to an individual pixel
    int pixNum = blockIdx.x * blockDim.x + threadIdx.x;

    if (!(pixNum >= 0 && pixNum < rows * cols)) {
        return;
    }
   
    double kernelSum;
    double redPixelVal;
    double greenPixelVal;
    double bluePixelVal;

    //Apply Kernel to each pixel of image
    for (int i = 0; i < G_KERNEL_SIZE; ++i) {
        for (int j = 0; j < G_KERNEL_SIZE; ++j) {    
        
            //check edge cases, if within bounds, apply filter
            if (((pixNum + ((i - ((G_KERNEL_SIZE - 1) / 2))*cols) + j - ((G_KERNEL_SIZE - 1) / 2)) >= 0)
                && ((pixNum + ((i - ((G_KERNEL_SIZE - 1) / 2))*cols) + j - ((G_KERNEL_SIZE - 1) / 2)) <= rows*cols-1)
                && (((pixNum % cols) + j - ((G_KERNEL_SIZE-1)/2)) >= 0)
                && (((pixNum % cols) + j - ((G_KERNEL_SIZE-1)/2)) <= (cols-1))) {

                redPixelVal += kernel[i][j] * in_pixels[pixNum + ((i - ((G_KERNEL_SIZE - 1) / 2))*cols) + j - ((G_KERNEL_SIZE - 1) / 2)].r;
                greenPixelVal += kernel[i][j] * in_pixels[pixNum + ((i - ((G_KERNEL_SIZE - 1) / 2))*cols) + j - ((G_KERNEL_SIZE - 1) / 2)].g;
                bluePixelVal += kernel[i][j] * in_pixels[pixNum + ((i - ((G_KERNEL_SIZE - 1) / 2))*cols) + j - ((G_KERNEL_SIZE - 1) / 2)].b;
                kernelSum += kernel[i][j];
            }
        }
    }
    
    //update output image
    out_pixels[pixNum].r = redPixelVal / kernelSum;
    out_pixels[pixNum].g = greenPixelVal / kernelSum;
    out_pixels[pixNum].b = bluePixelVal / kernelSum;
    
}

//*****************************************************************************************
// CUDA Intensity Gradient Implementation
//*****************************************************************************************

///
/// \brief Compute gradient (first order derivative x and y). This is the CUDA kernel for taking the derivative of color contrasts in adjacent images.
///
__global__
void compute_intensity_gradient_gpu(pixel_t *in_pixels, channel_t_signed *deltaX_channel, channel_t_signed *deltaY_channel, unsigned parser_length, unsigned offset)
{
    // compute delta X ***************************
    // deltaX = f(x+1) - f(x-1)
    
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    
    /* condition here skips first and last row */
    if ((idx > offset) && (idx < (parser_length * offset) - offset))
    {
        int16_t deltaXred = 0;
        int16_t deltaYred = 0;
        int16_t deltaXgreen = 0;
        int16_t deltaYgreen = 0;
        int16_t deltaXblue = 0;
        int16_t deltaYblue = 0;

        /* first column */
        if((idx % offset) == 0)
        {
            // gradient at the first pixel of each line
            // note: at the edge pix[idx-1] does NOT exist
            deltaXred = (int16_t)(in_pixels[idx+1].r - in_pixels[idx].r);
            deltaXgreen = (int16_t)(in_pixels[idx+1].g - in_pixels[idx].g);
            deltaXblue = (int16_t)(in_pixels[idx+1].b - in_pixels[idx].b);
            // gradient at the first pixel of each line
            // note: at the edge pix[idx-1] does NOT exist
            deltaYred = (int16_t)(in_pixels[idx+offset].r - in_pixels[idx].r);
            deltaYgreen = (int16_t)(in_pixels[idx+offset].g - in_pixels[idx].g);
            deltaYblue = (int16_t)(in_pixels[idx+offset].b - in_pixels[idx].b);
        }
        /* last column */
        else if((idx % offset) == (offset - 1))
        {
            deltaXred = (int16_t)(in_pixels[idx].r - in_pixels[idx-1].r);
            deltaXgreen = (int16_t)(in_pixels[idx].g - in_pixels[idx-1].g);
            deltaXblue = (int16_t)(in_pixels[idx].b - in_pixels[idx-1].b);

            deltaYred = (int16_t)(in_pixels[idx].r - in_pixels[idx-offset].r);
            deltaYgreen = (int16_t)(in_pixels[idx].g - in_pixels[idx-offset].g);
            deltaYblue = (int16_t)(in_pixels[idx].b - in_pixels[idx-offset].b);
        }
        /* gradients where NOT edge */
        else
        {
            deltaXred = (int16_t)(in_pixels[idx+1].r - in_pixels[idx-1].r);
            deltaXgreen = (int16_t)(in_pixels[idx+1].g - in_pixels[idx-1].g);
            deltaXblue = (int16_t)(in_pixels[idx+1].b - in_pixels[idx-1].b);
            deltaYred = (int16_t)(in_pixels[idx+offset].r - in_pixels[idx-offset].r);
            deltaYgreen = (int16_t)(in_pixels[idx+offset].g - in_pixels[idx-offset].g);
            deltaYblue = (int16_t)(in_pixels[idx+offset].b - in_pixels[idx-offset].b);
        }
        deltaX_channel[idx] = (int16_t)(0.2989 * deltaXred + 0.5870 * deltaXgreen + 0.1140 * deltaXblue);
        deltaY_channel[idx] = (int16_t)(0.2989 * deltaYred + 0.5870 * deltaYgreen + 0.1140 * deltaYblue); 
    }
}

//*****************************************************************************************
// CUDA Gradient Magnitude Implementation
//*****************************************************************************************

///
/// \brief Compute magnitude of gradient(deltaX & deltaY) per pixel.
///
__global__
void magnitude_gpu(channel_t_signed *deltaX, channel_t_signed *deltaY, channel_t *out_pixel, unsigned parser_length, unsigned offset)
{
    //computation
    //Assigned a thread to each pixel
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= 0 && idx < parser_length * offset) {
            out_pixel[idx] =  (channel_t)(sqrt((double)deltaX[idx]*deltaX[idx] + 
                            (double)deltaY[idx]*deltaY[idx]) + 0.5);
    }
}

//*****************************************************************************************
// CUDA Non Maximal Suppression Implementation
//*****************************************************************************************

///
/// \brief Non Maximal Suppression
/// If the centre pixel is not greater than neighboured pixels in the direction,
/// then the center pixel is set to zero.
/// This process results in one pixel wide ridges.
///
__global__
void suppress_non_max_gpu(channel_t *mag, channel_t_signed *deltaX, channel_t_signed *deltaY, channel_t *nms, unsigned parser_length, unsigned offset)
{
   
    const channel_t SUPPRESSED = 0;

    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (! (idx >= 0 && idx < parser_length * offset)) {return;}
    float alpha;
    float mag1, mag2;
    // put zero all boundaries of image
    // TOP edge line of the image
    if((idx >= 0) && (idx <offset)){
        nms[idx] = 0;
    }
    // BOTTOM edge line of image
    else if((idx >= (parser_length-1)*offset) && (idx < (offset * parser_length))){
        nms[idx] = 0;
    }
    // LEFT & RIGHT edge line
    else if(((idx % offset)==0) || ((idx % offset)==(offset - 1))){
        nms[idx] = 0;
    }
    // not the boundaries
    else {
        // if magnitude = 0, no edge
        if(mag[idx] == 0){
            nms[idx] = SUPPRESSED;
        }
        else{
            if(deltaX[idx] >= 0)
            {
                if(deltaY[idx] >= 0)  // dx >= 0, dy >= 0
                {
                    if((deltaX[idx] - deltaY[idx]) >= 0)       // direction 1 (SEE, South-East-East)
                    {
                        alpha = (float)deltaY[idx] / deltaX[idx];
                        mag1 = (1-alpha)*mag[idx+1] + alpha*mag[idx+offset+1];
                        mag2 = (1-alpha)*mag[idx-1] + alpha*mag[idx-offset-1];
                    }
                    else                                // direction 2 (SSE)
                    {
                        alpha = (float)deltaX[idx] / deltaY[idx];
                        mag1 = (1-alpha)*mag[idx+offset] + alpha*mag[idx+offset+1];
                        mag2 = (1-alpha)*mag[idx-offset] + alpha*mag[idx-offset-1];
                    }
                }
                else  // dx >= 0, dy < 0
                {
                    if((deltaX[idx] + deltaY[idx]) >= 0)    // direction 8 (NEE)
                    {
                        alpha = (float)-deltaY[idx] / deltaX[idx];
                        mag1 = (1-alpha)*mag[idx+1] + alpha*mag[idx-offset+1];
                        mag2 = (1-alpha)*mag[idx-1] + alpha*mag[idx+offset-1];
                    }
                    else                                // direction 7 (NNE)
                    {
                        alpha = (float)deltaX[idx] / -deltaY[idx];
                        mag1 = (1-alpha)*mag[idx+offset] + alpha*mag[idx+offset-1];
                        mag2 = (1-alpha)*mag[idx-offset] + alpha*mag[idx-offset+1];
                    }
                }
            }

            else
            {
                if(deltaY[idx] >= 0) // dx < 0, dy >= 0
                {
                    if((deltaX[idx] + deltaY[idx]) >= 0)    // direction 3 (SSW)
                    {
                        alpha = (float)-deltaX[idx] / deltaY[idx];
                        mag1 = (1-alpha)*mag[idx+offset] + alpha*mag[idx+offset-1];
                        mag2 = (1-alpha)*mag[idx-offset] + alpha*mag[idx-offset+1];
                    }
                    else                                // direction 4 (SWW)
                    {
                        alpha = (float)deltaY[idx] / -deltaX[idx];
                        mag1 = (1-alpha)*mag[idx-1] + alpha*mag[idx+offset-1];
                        mag2 = (1-alpha)*mag[idx+1] + alpha*mag[idx-offset+1];
                    }
                }

                else // dx < 0, dy < 0
                {
                        if((-deltaX[idx] + deltaY[idx]) >= 0)   // direction 5 (NWW)
                        {
                            alpha = (float)deltaY[idx] / deltaX[idx];
                            mag1 = (1-alpha)*mag[idx-1] + alpha*mag[idx-offset-1];
                            mag2 = (1-alpha)*mag[idx+1] + alpha*mag[idx+offset+1];
                        }
                        else                                // direction 6 (NNW)
                        {
                            alpha = (float)deltaX[idx] / deltaY[idx];
                            mag1 = (1-alpha)*mag[idx-offset] + alpha*mag[idx-offset-1];
                            mag2 = (1-alpha)*mag[idx+offset] + alpha*mag[idx+offset+1];
                        }
                }
            }

            // non-maximal suppression
            // compare mag1, mag2 and mag[t]
            // if mag[t] is smaller than one of the neighbours then suppress it
            if((mag[idx] < mag1) || (mag[idx] < mag2))
                    nms[idx] = SUPPRESSED;
            else
            {
                    nms[idx] = mag[idx];
            }
        } // END OF ELSE (mag != 0)
    } // END OF FOR(j)
}

//*****************************************************************************************
// CUDA Hysteresis Implementation
//*****************************************************************************************

///
/// \brief This is a helper function that runs on the GPU.
///
/// It checks if the eight immediate neighbors of a pixel at a given index are above
/// a low threshold, and if they are, sets them to strong edges. This effectively
/// connects the edges.
///
__device__
void trace_immed_neighbors(channel_t *out_pixels, channel_t *in_pixels, 
                            unsigned idx, channel_t t_low, unsigned img_width)
{
    /* directions representing indices of neighbors */
    unsigned n, s, e, w;
    unsigned nw, ne, sw, se;

    /* get indices */
    n = idx - img_width;
    nw = n - 1;
    ne = n + 1;
    s = idx + img_width;
    sw = s - 1;
    se = s + 1;
    w = idx - 1;
    e = idx + 1;

    if (in_pixels[nw] >= t_low) {
        out_pixels[nw] = STRONG_EDGE;
    }
    if (in_pixels[n] >= t_low) {
        out_pixels[n] = STRONG_EDGE;
    }
    if (in_pixels[ne] >= t_low) {
        out_pixels[ne] = STRONG_EDGE;
    }
    if (in_pixels[w] >= t_low) {
        out_pixels[w] = STRONG_EDGE;
    }
    if (in_pixels[e] >= t_low) {
        out_pixels[e] = STRONG_EDGE;
    }
    if (in_pixels[sw] >= t_low) {
        out_pixels[sw] = STRONG_EDGE;
    }
    if (in_pixels[s] >= t_low) {
        out_pixels[s] = STRONG_EDGE;
    }
    if (in_pixels[se] >= t_low) {
        out_pixels[se] = STRONG_EDGE;
    }
}

///
/// \brief CUDA implementation of Canny hysteresis high thresholding.
///
/// This kernel is the first pass in the parallel hysteresis step.
/// It launches a thread for every pixel and checks if the value of that pixel
/// is above a high threshold. If it is, the thread marks it as a strong edge (set to 1)
/// in a pixel map and sets the value to the channel max. If it is not, the thread sets
/// the pixel map at the index to 0 and zeros the output buffer space at that index.
///
/// The output of this step is a mask of strong edges and an output buffer with white values
/// at the mask indices which are set.
///
__global__
void hysteresis_high_gpu(channel_t *out_pixels, channel_t *in_pixels, unsigned *strong_edge_mask, 
                        channel_t t_high, unsigned img_height, unsigned img_width)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= (img_height * img_width)) {return;} // OOB
    
    /* apply high threshold */
    if (in_pixels[idx] > t_high) {
        strong_edge_mask[idx] = 1;
        out_pixels[idx] = STRONG_EDGE;
    } else {
        strong_edge_mask[idx] = 0;
        out_pixels[idx] = NON_EDGE;
    }
}

///
/// \brief CUDA implementation of Canny hysteresis low thresholding.
///
/// This kernel is the second pass in the parallel hysteresis step. 
/// It launches a thread for every pixel, but skips the first and last rows and columns.
/// For surviving threads, the pixel at the thread ID index is checked to see if it was 
/// previously marked as a strong edge in the first pass. If it was, the thread checks 
/// their eight immediate neighbors and connects them (marks them as strong edges)
/// if the neighbor is above the low threshold.
///
/// The output of this step is an output buffer with both "strong" and "connected" edges
/// set to whtie values. This is the final edge detected image.
///
__global__
void hysteresis_low_gpu(channel_t *out_pixels, channel_t *in_pixels, unsigned *strong_edge_mask,
                        unsigned t_low, unsigned img_height, unsigned img_width)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if ((idx > img_width)                               /* skip first row */
        && (idx < (img_height * img_width) - img_width) /* skip last row */
        && ((idx % img_width) < (img_width - 1))        /* skip last column */
        && ((idx % img_width) > (0)) )                  /* skip first column */
    {
        if (1 == strong_edge_mask[idx]) { /* if this pixel was previously found to be a strong edge */
            trace_immed_neighbors(out_pixels, in_pixels, idx, t_low, img_width);
        }
    }
}


//*****************************************************************************************
// Entry point for serial program calling CUDA implementation
//*****************************************************************************************

void canny_gpu(channel_t *final_pixels, pixel_t *orig_pixels, int rows, int cols, double kernel[G_KERNEL_SIZE][G_KERNEL_SIZE]) 
{
    /* kernel execution configuration parameters */
    int num_blks = (rows * cols) / 1024;
    int thd_per_blk = 1024;
    int grid = 0;
    channel_t t_high = 0xFCC;
    channel_t t_low = 0xF5;

    /* device buffers */ 
    pixel_t *in, *out;
    channel_t *single_channel_buf0;
    channel_t *single_channel_buf1;
    channel_t_signed *deltaX;
    channel_t_signed *deltaY;
    double *d_blur_kernel;
    unsigned *idx_map;

    /* allocate device memory */
    cudaMalloc((void**) &in, sizeof(pixel_t)*rows*cols); 
    cudaMalloc((void**) &out, sizeof(pixel_t)*rows*cols); 
    cudaMalloc((void**) &single_channel_buf0, sizeof(channel_t)*rows*cols); 
    cudaMalloc((void**) &single_channel_buf1, sizeof(channel_t)*rows*cols); 
    cudaMalloc((void**) &deltaX, sizeof(channel_t_signed)*rows*cols);
    cudaMalloc((void**) &deltaY, sizeof(channel_t_signed)*rows*cols);
    cudaMalloc((void**) &idx_map, sizeof(idx_map[0])*rows*cols);
    cudaMalloc((void**) &d_blur_kernel, sizeof(d_blur_kernel[0])*G_KERNEL_SIZE*G_KERNEL_SIZE);

    /* data transfer image pixels to device */
    cudaMemcpy(in, orig_pixels, rows*cols*sizeof(pixel_t), cudaMemcpyHostToDevice);
    cudaMemcpy(d_blur_kernel, kernel, sizeof(d_blur_kernel[0])*G_KERNEL_SIZE*G_KERNEL_SIZE, cudaMemcpyHostToDevice);

    /* run canny edge detection core - CUDA kernels */
    /* use streams to ensure the kernels are in the same task */
    cudaStream_t stream;
    cudaStreamCreate(&stream);
    apply_gaussian_filter_gpu<<<num_blks, thd_per_blk, grid, stream>>>(in, out, rows, cols, d_blur_kernel);
    compute_intensity_gradient_gpu<<<num_blks, thd_per_blk, grid, stream>>>(out, deltaX, deltaY, rows, cols);
    magnitude_gpu<<<num_blks, thd_per_blk, grid, stream>>>(deltaX, deltaY, single_channel_buf0, rows, cols);
    suppress_non_max_gpu<<<num_blks, thd_per_blk, grid, stream>>>(single_channel_buf0, deltaX, deltaY, single_channel_buf1, rows, cols);
    hysteresis_high_gpu<<<num_blks, thd_per_blk, grid, stream>>>(single_channel_buf0, single_channel_buf1, idx_map, t_high, rows, cols);
    hysteresis_low_gpu<<<num_blks, thd_per_blk, grid, stream>>>(single_channel_buf0, single_channel_buf1, idx_map, t_low, rows, cols);

    /* wait for everything to finish */
    cudaDeviceSynchronize();

    /* copy result back to the host */
    cudaMemcpy(final_pixels, single_channel_buf0, rows*cols*sizeof(channel_t), cudaMemcpyDeviceToHost);

    /* cleanup */
    cudaFree(in);
    cudaFree(out);
    cudaFree(single_channel_buf0);
    cudaFree(single_channel_buf1);
    cudaFree(deltaX);
    cudaFree(deltaY);
    cudaFree(idx_map);
    cudaFree(d_blur_kernel);
}

//*****************************************************************************************
// Test/Debug hooks for separate kernels
// These generally aren't to be used, but can serve as drop-in replacements for any
// particular step of the algorithm's serial implementation.
// Useful for debugging individual kernels.
//*****************************************************************************************

void test_gradient_gpu(pixel_t *buf0, channel_t_signed *deltaX_gray, channel_t_signed *deltaY_gray, unsigned rows, unsigned cols)
{
    pixel_t *in_pixels;
    channel_t_signed *deltaX;
    channel_t_signed *deltaY;
    
    cudaMalloc((void**) &in_pixels, sizeof(pixel_t)*rows*cols); 
    cudaMalloc((void**) &deltaX, sizeof(channel_t_signed)*rows*cols);
    cudaMalloc((void**) &deltaY, sizeof(channel_t_signed)*rows*cols);

    cudaMemcpy(in_pixels, buf0, rows*cols*sizeof(pixel_t), cudaMemcpyHostToDevice);

    compute_intensity_gradient_gpu<<<(rows*cols)/1024, 1024>>>(in_pixels, deltaX, deltaY, rows, cols);

    cudaMemcpy(deltaX_gray, deltaX, rows*cols*sizeof(channel_t_signed), cudaMemcpyDeviceToHost);
    cudaMemcpy(deltaY_gray, deltaY, rows*cols*sizeof(channel_t_signed), cudaMemcpyDeviceToHost);

    cudaFree(in_pixels);
    cudaFree(deltaX);
    cudaFree(deltaY);
}

void test_mag_gpu(channel_t_signed *deltaX, channel_t_signed *deltaY, channel_t *out_pixel, unsigned rows, unsigned cols)
{
    channel_t *magnitude_v;
    channel_t_signed *deltaX_gray;
    channel_t_signed *deltaY_gray;

    cudaMalloc((void**) &magnitude_v, sizeof(channel_t)*rows*cols); 
    cudaMalloc((void**) &deltaX_gray, sizeof(channel_t_signed)*rows*cols);
    cudaMalloc((void**) &deltaY_gray, sizeof(channel_t_signed)*rows*cols);

    cudaMemcpy(deltaX_gray, deltaX, rows*cols*sizeof(channel_t_signed), cudaMemcpyHostToDevice);
    cudaMemcpy(deltaY_gray, deltaY, rows*cols*sizeof(channel_t_signed), cudaMemcpyHostToDevice);

    magnitude_gpu<<<(rows*cols)/1024, 1024>>>(deltaX_gray, deltaY_gray, magnitude_v, rows, cols);

    cudaMemcpy(out_pixel, magnitude_v, rows*cols*sizeof(channel_t_signed), cudaMemcpyDeviceToHost);

    cudaFree(magnitude_v);
    cudaFree(deltaX_gray);
    cudaFree(deltaY_gray);
}

void test_nonmax_gpu(channel_t *mag, channel_t_signed *deltaX, channel_t_signed *deltaY, channel_t *nms, unsigned rows, unsigned cols)
{
    channel_t *magnitude_v;
    channel_t *d_nms;
    channel_t_signed *deltaX_gray;
    channel_t_signed *deltaY_gray;

    cudaMalloc((void**) &magnitude_v, sizeof(channel_t)*rows*cols); 
    cudaMalloc((void**) &d_nms, sizeof(channel_t)*rows*cols); 
    cudaMalloc((void**) &deltaX_gray, sizeof(channel_t_signed)*rows*cols);
    cudaMalloc((void**) &deltaY_gray, sizeof(channel_t_signed)*rows*cols);

    cudaMemcpy(magnitude_v, mag, rows*cols*sizeof(channel_t), cudaMemcpyHostToDevice);
    cudaMemcpy(deltaX_gray, deltaX, rows*cols*sizeof(channel_t_signed), cudaMemcpyHostToDevice);
    cudaMemcpy(deltaY_gray, deltaY, rows*cols*sizeof(channel_t_signed), cudaMemcpyHostToDevice);

    suppress_non_max_gpu<<<(rows*cols)/1024, 1024>>>(magnitude_v, deltaX_gray, deltaY_gray, d_nms, rows, cols);

    cudaMemcpy(nms, d_nms, rows*cols*sizeof(channel_t), cudaMemcpyDeviceToHost);
    
    cudaFree(magnitude_v);
    cudaFree(d_nms);
    cudaFree(deltaX_gray);
    cudaFree(deltaY_gray);
}

void test_hysteresis_gpu(channel_t *in, channel_t *out, unsigned rows, unsigned cols)
{
    channel_t *in_pixels, *out_pixels;
    unsigned *idx_map;

    /* allocate device memory */
    cudaMalloc((void**) &in_pixels, rows*cols*sizeof(channel_t));
    cudaMalloc((void**) &out_pixels, rows*cols*sizeof(channel_t));
    cudaMalloc((void**) &idx_map, rows*cols*sizeof(idx_map[0]));

    /* copy original pixels to GPU device as in_pixels*/
    cudaMemcpy(in_pixels, in, rows*cols*sizeof(channel_t), cudaMemcpyHostToDevice);
      
    channel_t t_high = 0xFCC;
    channel_t t_low = 0x1FF;

    /* create task stream to sequence kernels */
    cudaStream_t stream;
    cudaStreamCreate(&stream);

    /* launch kernels */
    hysteresis_high_gpu<<<(rows*cols)/1024, 1024, 0, stream>>>(out_pixels, in_pixels, idx_map, t_high, rows, cols);
    hysteresis_low_gpu<<<(rows*cols)/1024, 1024, 0, stream>>>(out_pixels, in_pixels, idx_map, t_low, rows, cols);

    /* copy blurred pixels from GPU device back to host as out_pixels*/
    cudaMemcpy(out, out_pixels, rows*cols*sizeof(channel_t), cudaMemcpyDeviceToHost);

    cudaFree(in_pixels);
    cudaFree(out_pixels);
    cudaFree(idx_map);
}