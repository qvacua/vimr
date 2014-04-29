/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */


#ifndef __VRCppUtils_H_
#define __VRCppUtils_H_


extern size_t count_slashes(std::string const &s1, std::string const &s2);
extern std::vector<std::pair<size_t, size_t>> chunked_indexes(size_t count, size_t chunkSize);
extern std::vector<size_t> disambiguate(std::vector<std::string> const &paths);
extern void enumerate_array_in_range(NSArray *array, std::pair<size_t, size_t> pair, void (^block)(id));

/**
* shouldStopBeforeChunk() is called before each chunk execution and if it returns YES, we stop and return NO, ie
* the enumeration was not complete, but was cancelled.
*/
BOOL chunk_enumerate_array(NSArray *array, size_t chunkSize, BOOL (^shouldStopBeforeChunk)(void), void (^blockOnChild)(id));

#endif //__VRCppUtils_H_
