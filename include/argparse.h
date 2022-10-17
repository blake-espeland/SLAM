#pragma once
#include <argp.h>

static char doc[] =
"vSLAM written in C++ and CUDA. \n\
	Takes an input video file and displays the vSLAM output. \n\
	Currently only supports GPU execution on NVIDIA devices. \n";

static struct argp_option options[] = {
    {"input-video", 'i', "FILENAME", 0, "Input video filename.", 0},
    {0, 0, 0, 0, 0, 0}
};

struct Arguments{
    char* src;
};


/* Parser */
static error_t parse_opt (int key, char *arg, struct argp_state *state)
{
    struct Arguments *args = (Arguments *)state->input;

    switch(key) 
    {
        case 'i':
            args->src = arg;
            break;
        default:
            return ARGP_ERR_UNKNOWN;
    }

    return 0;
}

static struct argp _argp = {options, parse_opt, NULL, doc, 0, 0, 0};