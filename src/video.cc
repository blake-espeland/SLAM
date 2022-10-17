#include "video.h"
#include "pixel.h"
#include <opencv2/core/matx.hpp>
#include <opencv2/videoio.hpp>


Video::Video(const char* src){
    vc = cv::VideoCapture(src);

    h = vc.get(cv::CAP_PROP_XI_HEIGHT);
    w = vc.get(cv::CAP_PROP_XI_WIDTH);
    size = (h * w);

    mod = (pixel_t*)malloc(size * sizeof(pixel_t));
}

Video::~Video(){
    std::free(mod);
    vc.release();
}

pixel_t* Video::get(){
    vc >> orig;

    cv::Size _s = orig.size();
    size_t s = _s.width * _s.height;

    for (int r = 0; r < orig.rows; r++){
        for (int c = 0; c < orig.cols; c++){
            cv::Vec3b ch = orig.at<cv::Vec3b>(r, c);
            mod[r * orig.rows + c] = {ch[0], ch[1], ch[2]};
        }
    }
    return mod;
}