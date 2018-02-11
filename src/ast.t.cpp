

#include <gtest/gtest.h>
#include <gmock/gmock.h>

#include "ast.h"

using namespace testing;

template<typename T>
const T& get(std::list<T>& lst, size_t n)
{
  auto it = lst.begin();
  std::advance(it, n);
  return *it;
}

TEST(expression, smoke_test)
{
  expression e1(1);
  expression e2(2);
  
  expr_list elst;
  elst.push_back(std::move(e1));
  elst.push_back(std::move(e2));

  EXPECT_THAT(get(elst,0).type, Eq(ex_type::number));
  EXPECT_THAT(get(elst,1).type, Eq(ex_type::number));
  
  EXPECT_THAT(get(elst,0).number_value, Eq(1));
  EXPECT_THAT(get(elst,1).number_value, Eq(2));
}

TEST(expression, var_set)
{
  expression e1("i1", expression());

  auto varSet = e1.varSet();

  EXPECT_THAT(varSet.size(), Eq(1));

  expr_list elst;
  elst.emplace_back("i1", expression());
  elst.emplace_back("i2", expression());

  varSet = expression(std::move(elst)).varSet();

  EXPECT_THAT(varSet.size(), Eq(2));
}

TEST(expression, addParam)
{
  expression e1;

  EXPECT_THAT(e1.params.size(), Eq(0));
  e1.addParam(expression("i1", expression()));
  EXPECT_THAT(e1.params.size(), Eq(1));
  e1.addParam(expression("i1", expression()));
  EXPECT_THAT(e1.params.size(), Eq(2));
}
