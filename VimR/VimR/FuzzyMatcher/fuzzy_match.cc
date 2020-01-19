// Copyright 2017-2018 ccls Authors
// SPDX-License-Identifier: Apache-2.0

#include "fuzzy_match.hh"

#include <algorithm>
#include <ctype.h>
#include <stdio.h>
#include <vector>

namespace ccls {
namespace {
enum CharClass { Other, Lower, Upper };
enum CharRole { None, Tail, Head };

CharClass getCharClass(int c) {
  if (islower(c))
    return Lower;
  if (isupper(c))
    return Upper;
  return Other;
}

void calculateRoles(std::string_view s, int roles[], int *class_set) {
  if (s.empty()) {
    *class_set = 0;
    return;
  }
  CharClass pre = Other, cur = getCharClass(s[0]), suc;
  *class_set = 1 << cur;
  auto fn = [&]() {
    if (cur == Other)
      return None;
    // U(U)L is Head while U(U)U is Tail
    return pre == Other || (cur == Upper && (pre == Lower || suc == Lower))
               ? Head
               : Tail;
  };
  for (size_t i = 0; i < s.size() - 1; i++) {
    suc = getCharClass(s[i + 1]);
    *class_set |= 1 << suc;
    roles[i] = fn();
    pre = cur;
    cur = suc;
  }
  roles[s.size() - 1] = fn();
}
} // namespace

int FuzzyMatcher::missScore(int j, bool last) {
  int s = -3;
  if (last)
    s -= 10;
  if (text_role[j] == Head)
    s -= 10;
  return s;
}

int FuzzyMatcher::matchScore(int i, int j, bool last) {
  int s = 0;
  // Case matching.
  if (pat[i] == text[j]) {
    s++;
    // pat contains uppercase letters or prefix matching.
    if ((pat_set & 1 << Upper) || i == j)
      s++;
  }
  if (pat_role[i] == Head) {
    if (text_role[j] == Head)
      s += 30;
    else if (text_role[j] == Tail)
      s -= 10;
  }
  // Matching a tail while previous char wasn't matched.
  if (text_role[j] == Tail && i && !last)
    s -= 30;
  // First char of pat matches a tail.
  if (i == 0 && text_role[j] == Tail)
    s -= 40;
  return s;
}

FuzzyMatcher::FuzzyMatcher(std::string_view pattern, int sensitivity) {
  calculateRoles(pattern, pat_role, &pat_set);
  if (sensitivity == 1)
    sensitivity = pat_set & 1 << Upper ? 2 : 0;
  case_sensitivity = sensitivity;
  size_t n = 0;
  for (size_t i = 0; i < pattern.size(); i++)
    if (pattern[i] != ' ') {
      pat += pattern[i];
      low_pat[n] = (char)::tolower(pattern[i]);
      pat_role[n] = pat_role[i];
      n++;
    }
}

int FuzzyMatcher::match(std::string_view text, bool strict) {
  if (pat.empty() != text.empty())
    return kMinScore;
  int n = int(text.size());
  if (n > kMaxText)
    return kMinScore + 1;
  this->text = text;
  for (int i = 0; i < n; i++)
    low_text[i] = (char)::tolower(text[i]);
  calculateRoles(text, text_role, &text_set);
  if (strict && n && !!pat_role[0] != !!text_role[0])
    return kMinScore;
  dp[0][0][0] = dp[0][0][1] = 0;
  for (int j = 0; j < n; j++) {
    dp[0][j + 1][0] = dp[0][j][0] + missScore(j, false);
    dp[0][j + 1][1] = kMinScore * 2;
  }
  for (int i = 0; i < int(pat.size()); i++) {
    int(*pre)[2] = dp[i & 1];
    int(*cur)[2] = dp[(i + 1) & 1];
    cur[i][0] = cur[i][1] = kMinScore;
    for (int j = i; j < n; j++) {
      cur[j + 1][0] = std::max(cur[j][0] + missScore(j, false),
                               cur[j][1] + missScore(j, true));
      // For the first char of pattern, apply extra restriction to filter bad
      // candidates (e.g. |int| in |PRINT|)
      cur[j + 1][1] = (case_sensitivity ? pat[i] == text[j]
                                        : low_pat[i] == low_text[j] &&
                                              (i || text_role[j] != Tail ||
                                               pat[i] == text[j]))
                          ? std::max(pre[j][0] + matchScore(i, j, false),
                                     pre[j][1] + matchScore(i, j, true))
                          : kMinScore * 2;
    }
  }

  // Enumerate the end position of the match in str. Each removed trailing
  // character has a penulty.
  int ret = kMinScore;
  for (int j = pat.size(); j <= n; j++)
    ret = std::max(ret, dp[pat.size() & 1][j][1] - 2 * (n - j));
  return ret;
}
} // namespace ccls

#if 0
TEST_SUITE("fuzzy_match") {
  bool Ranks(std::string_view pat, std::vector<const char*> texts) {
    FuzzyMatcher fuzzy(pat, 0);
    std::vector<int> scores;
    for (auto text : texts)
      scores.push_back(fuzzy.Match(text));
    bool ret = true;
    for (size_t i = 0; i < texts.size() - 1; i++)
      if (scores[i] < scores[i + 1]) {
        ret = false;
        break;
      }
    if (!ret) {
      for (size_t i = 0; i < texts.size(); i++)
        printf("%s %d ", texts[i], scores[i]);
      puts("");
    }
    return ret;
  }

  TEST_CASE("test") {
    FuzzyMatcher fuzzy("", 0);
    CHECK(fuzzy.Match("") == 0);
    CHECK(fuzzy.Match("aaa") < 0);

    // case
    CHECK(Ranks("monad", {"monad", "Monad", "mONAD"}));
    // initials
    CHECK(Ranks("ab", {"ab", "aoo_boo", "acb"}));
    CHECK(Ranks("CC", {"CamelCase", "camelCase", "camelcase"}));
    CHECK(Ranks("cC", {"camelCase", "CamelCase", "camelcase"}));
    CHECK(Ranks("c c", {"camelCase", "camel case", "CamelCase", "camelcase",
                        "camel ace"}));
    CHECK(Ranks("Da.Te",
                {"Data.Text", "Data.Text.Lazy", "Data.Aeson.Encoding.text"}));
    CHECK(Ranks("foo bar.h", {"foo/bar.h", "foobar.h"}));
    // prefix
    CHECK(Ranks("is", {"isIEEE", "inSuf"}));
    // shorter
    CHECK(Ranks("ma", {"map", "many", "maximum"}));
    CHECK(Ranks("print", {"printf", "sprintf"}));
    // score(PRINT) = kMinScore
    CHECK(Ranks("ast", {"ast", "AST", "INT_FAST16_MAX"}));
    // score(PRINT) > kMinScore
    CHECK(Ranks("Int", {"int", "INT", "PRINT"}));
  }
}
#endif
