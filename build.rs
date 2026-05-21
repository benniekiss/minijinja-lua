fn main() {
    if std::env::var("PROFILE").unwrap_or_default() == "release" {
        println!("cargo:rustc-flags=-Zlocation-detail=none");
        println!("cargo:rustc-flags=-Zfmt-debug=none");
    }

    if cfg!(target_os = "macos") {
        println!("cargo:rustc-cdylib-link-arg=-undefined");
        println!("cargo:rustc-cdylib-link-arg=dynamic_lookup");
    }
}
