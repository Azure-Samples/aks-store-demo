
use wasmtime_wasi::preview2::{WasiView, Table, WasiCtx, WasiCtxBuilder};
use wasmtime::component::*;

use super::aksstoredemo::rules::logging::{self, HostLogger};
use super::aksstoredemo::rules::types::Host as HostTypes;
use log::info;

pub struct RulesEngineState {
    table: Table,
    wasi_ctx: WasiCtx,
}

impl RulesEngineState {
    pub fn new() -> Self {
        let wasi_ctx = WasiCtxBuilder::new().inherit_stdio().build();
        let table = Table::new();
        Self {
            table,
            wasi_ctx,
        }
    }
}

impl WasiView for RulesEngineState {
    fn table(&self) -> &Table {
        return &self.table;
    }

    fn table_mut(&mut self) -> &mut Table {
        return &mut self.table;
    }

    fn ctx(&self) -> &WasiCtx {
        return &self.wasi_ctx;
    }

    fn ctx_mut(&mut self) -> &mut WasiCtx {
        return &mut self.wasi_ctx;
    }
}


impl HostLogger for RulesEngineState {
    fn log(&mut self,
         this: Resource<logging::Logger>,
         message: String
        ) -> anyhow::Result<()>  {
        let resource: Resource<MyLogger> = Resource::new_own(this.rep());
        self
            .table()
            .get::<MyLogger>(&resource)?;

        info!("{}", message);
        Ok(())
    }
    fn drop(&mut self, this: Resource<logging::Logger>) -> anyhow::Result<()> {
        let resource: Resource<MyLogger> = Resource::new_own(this.rep());
        Ok(self
            .table_mut()
            .delete::<MyLogger>(resource)
            .map(|_| ())?)
    }
}

impl HostTypes for RulesEngineState {
}


struct MyLogger;

impl logging::Host for RulesEngineState {
    fn get_logger(&mut self) -> anyhow::Result<Resource<logging::Logger>> {
        let resource = self.table_mut().push::<MyLogger>(MyLogger)?;
        Ok(Resource::new_own(
            resource.rep(),
        ))
    }
}