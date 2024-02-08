# Try it

## Pre-Reqs

- Rust (tested with v1.74.0) and the correct toolchain for your local system and wasm32-wasi
- cargo component 0.5.0 (`cargo install cargo-component`)
- wasm-tools 1.0.54 compiled locally with the wasmtime dependency set to version = "15.0.1" - it may work as it sits in the repo, but I wanted to make sure all the things were using the same version of wasmtime.


## The Commands

```
pushd ../sample_rule
cargo component build --release
popd
pushd ../second_rule
cargo component build --release
popd
wasm-tools compose -o rule_engine.wasm -c config.yml ../second-rule/target/wasm32-wasi/release/second_rule.wasm 

cargo run
```

Then, using the REST Client extention and the http file in the root of the product-service source, add a product.

Then, try to update the product with a cost over 100 (the last example in the http file).  The action will error.
