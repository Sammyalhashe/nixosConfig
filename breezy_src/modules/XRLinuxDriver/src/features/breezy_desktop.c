#include "runtime_context.h"
#include "strings.h"

const char* productivity_basic_feature_name = "productivity_basic";
const char* productivity_pro_feature_name = "productivity_pro";

bool is_productivity_basic_granted() {
    return true;
}

bool is_productivity_pro_granted() {
    return true;
}

bool is_productivity_granted() {
    return true;
}