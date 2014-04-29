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


#endif //__VRCppUtils_H_
