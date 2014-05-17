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


BOOL chunk_enumerate_array(NSArray *array, size_t chunkSize, BOOL (^shouldStopBeforeChunk)(void), void (^blockOnChild)(id)) {
  std::vector<std::pair<size_t, size_t>> chunkedIndexes = chunked_indexes(array.count, chunkSize);
  for (auto &pair : chunkedIndexes) {
    if (shouldStopBeforeChunk()) {
      return NO;
    }

    size_t beginIndex = pair.first;
    size_t endIndex = pair.second;

    for (size_t i = beginIndex; i <= endIndex; i++) {
      blockOnChild(array[i]);
    }
  }

  return YES;
}

void enumerate_array_in_range(NSArray *array, std::pair<size_t, size_t> pair, void (^block)(id)) {
  size_t beginIndex = pair.first;
  size_t endIndex = pair.second;

  for (size_t i = beginIndex; i <= endIndex; i++) {
    block(array[i]);
  }
}

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

