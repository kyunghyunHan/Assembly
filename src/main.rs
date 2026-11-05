unsafe extern "C" {
    fn hello_asm();
}

fn main() {
    unsafe {
        hello_asm();
    }
}