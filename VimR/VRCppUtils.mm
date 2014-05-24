/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#include "VRCppUtils.h"
#include <numeric>


std::vector<std::pair<size_t, size_t>> chunked_indexes(size_t count, size_t size) {
  std::vector<std::pair<size_t, size_t>> result;

  if (count == 0) {
    return result;
  }

  size_t numberOfChunks = (size_t) (floor(count / size) + 1);

  if (size == count || numberOfChunks == 1) {
    std::pair<size_t, size_t> pair(0, count - 1);
    result.push_back(pair);

    return result;
  }

  size_t begin = 0;
  size_t end = 0;
  for (size_t i = 0; i < numberOfChunks; i++) {
    begin = i * size;
    if (i == numberOfChunks - 1) {
      end = count - 1;
    } else {
      end = size * (i + 1) - 1;
    }

    std::pair<size_t, size_t> pair(begin, end);
    result.push_back(pair);
  }

  return result;
}

