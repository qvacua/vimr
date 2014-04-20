#import "VRUtils.h"


double measure_time(void (^block)()) {
    clock_t tic = clock();
    block();
    clock_t toc = clock();

    return (double) (toc - tic) / CLOCKS_PER_SEC;
}
