#ifdef NDEBUG
#define SHR_ASSERT(assert, msg)
#define SHR_ASSERT_ALL(assert, msg)
#define SHR_ASSERT_ANY(assert, msg)
#else
#define SHR_ASSERT(assert, msg) call shr_assert(assert, msg)
#define SHR_ASSERT_ALL(assert, msg) call shr_assert_all(assert, msg)
#define SHR_ASSERT_ANY(assert, msg) call shr_assert_any(assert, msg)
#endif
use bshr_assert_mod, only : shr_assert
use bshr_assert_mod, only : shr_assert_all
use bshr_assert_mod, only : shr_assert_any

