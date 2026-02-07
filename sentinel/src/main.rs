use franklyn_sentinel::{debug, ws::connect_to_server_sync};

fn main() {
    debug();

    connect_to_server_sync();
}
