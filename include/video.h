#include <iterator>
#include <memory>
#include <opencv2/opencv.hpp>
#include <memory.h>

#include "pixel.h"

class Video {
        cv::VideoCapture vc;
        int h, w, size;
        int dtype;
        pixel_t* mod;

        cv::Mat orig;
    public:
        Video(const char* src);
        ~Video();
        pixel_t* get();
};