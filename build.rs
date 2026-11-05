fn main() {
    cc::Build::new()
        .file("src/hello.s")
        .compile("hello");
}