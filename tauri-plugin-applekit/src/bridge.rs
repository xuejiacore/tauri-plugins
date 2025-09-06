use std::ffi::c_char;

extern "C" {
    pub(crate) fn set_user_default(key: *const c_char, value: *const c_char) -> *const c_char;
    pub(crate) fn get_user_default(key: *const c_char) -> *const c_char;
}
