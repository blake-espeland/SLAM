#include <iostream>
#include <ostream>

#include "argparse.h"
#include "video.h"

int main(int argc, char** argv){
#ifndef GPU
    perror("Must be compiled using NVidia CUDA.");
    exit(0);
#endif
    struct Arguments args = {"test.mp4"};

    int rc = argp_parse(&_argp, argc, argv, 0, 0, &args);
    if (rc) {
        std::cerr << "Failed to parse command line arguments." << std::endl;
        exit(rc);
    }

    Video v(args.src);
    v.get();
}