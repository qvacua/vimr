/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#include "VRCppUtils.h"


std::vector<std::pair<NSUInteger, NSUInteger>> chunked_indexes(NSUInteger count, NSUInteger size) {
  NSUInteger numberOfChunks = (NSUInteger) (floor(count / size) + 1);

  std::vector<std::pair<NSUInteger, NSUInteger>> result;
  if (size == count || numberOfChunks == 1) {
    std::pair<NSUInteger, NSUInteger> pair;
    pair.first = 0;
    pair.second = count - 1;
    result.push_back(pair);

    return result;
  }

  NSUInteger begin = 0;
  NSUInteger end = 0;
  for (NSUInteger i = 0; i < numberOfChunks; i++) {
    begin = i * size;
    if (i == numberOfChunks - 1) {
      end = count - 1;
    } else {
      end = size * (i + 1) - 1;
    }

    std::pair<NSUInteger, NSUInteger> pair;
    pair.first = begin;
    pair.second = end;
    result.push_back(pair);
  }

  return result;
}
