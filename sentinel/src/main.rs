use franklyn_sentinel::{debug, ws::connect_to_server_sync};

fn main() {
    println!("Hello world");

    debug();

    connect_to_server_sync();
}
