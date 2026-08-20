use std::sync::atomic::{AtomicUsize, Ordering};

static LAST_RESULT_LEN: AtomicUsize = AtomicUsize::new(0);

#[unsafe(no_mangle)]
pub extern "C" fn hayagriva_alloc(len: usize) -> *mut u8 {
    let mut buffer = Vec::<u8>::with_capacity(len);
    let ptr = buffer.as_mut_ptr();
    std::mem::forget(buffer);
    ptr
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn hayagriva_dealloc(ptr: *mut u8, len: usize) {
    if ptr.is_null() {
        return;
    }
    unsafe {
        drop(Vec::from_raw_parts(ptr, 0, len));
    }
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn hayagriva_result_free(ptr: *mut u8, len: usize) {
    if ptr.is_null() {
        return;
    }
    unsafe {
        drop(Vec::from_raw_parts(ptr, len, len));
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn hayagriva_last_result_len() -> usize {
    LAST_RESULT_LEN.load(Ordering::Relaxed)
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn hayagriva_bibtex_to_yaml(ptr: *const u8, len: usize) -> *mut u8 {
    let input = unsafe { std::slice::from_raw_parts(ptr, len) };
    let output = match std::str::from_utf8(input) {
        Ok(source) => convert(source),
        Err(error) => format!("err\ninvalid UTF-8 input: {error}"),
    };
    into_result(output)
}

fn convert(source: &str) -> String {
    let bibliography = match hayagriva::io::from_biblatex_str(source) {
        Ok(bibliography) => bibliography,
        Err(errors) => {
            let details = errors
                .into_iter()
                .map(|error| error.to_string())
                .collect::<Vec<_>>()
                .join("; ");
            return format!("err\n{details}");
        }
    };

    match hayagriva::io::to_yaml_str(&bibliography) {
        Ok(yaml) => format!("ok\n{yaml}"),
        Err(error) => format!("err\nYAML serialization failed: {error}"),
    }
}

fn into_result(output: String) -> *mut u8 {
    let mut bytes = output.into_bytes().into_boxed_slice();
    let len = bytes.len();
    let ptr = bytes.as_mut_ptr();
    LAST_RESULT_LEN.store(len, Ordering::Relaxed);
    std::mem::forget(bytes);
    ptr
}
