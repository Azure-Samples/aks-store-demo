# virtual customer

To run the app locally, run the following commands:

```bash
export ORDERS_PER_MINUTE=100
cargo run
```

To run the app as a WASM module using wasmtime, run the following commands:

```bash
cargo build --target wasm32-wasi
wasmtime --env ORDERS_PER_MINUTE=100 ./target/wasm32-wasi/debug/virtual-customer.wasm
```
