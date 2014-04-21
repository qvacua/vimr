#import "VRUtils.h"


double measure_time(void (^block)()) {
  clock_t tic = clock();
  block();
  clock_t toc = clock();

  return (double) (toc - tic) / CLOCKS_PER_SEC;
}

void dispatch(dispatch_block_t block) {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}
