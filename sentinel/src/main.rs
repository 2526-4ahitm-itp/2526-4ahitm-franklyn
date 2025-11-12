fn main() {
    println!("{}", hello_world());

    let helloVar = "deimmo";

    println!("Hello, world!");
}

const fn hello_world() -> &'static str {
    "hello world"
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_hello_world() {
        println!("{}", hello_world());
        assert_eq!(hello_world(), "hello world");
    }

    #[test]
    fn test_hello_world2() {
        assert_eq!(hello_world(), "hello world");
    }
}
