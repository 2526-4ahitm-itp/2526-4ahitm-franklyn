//! Some util

pub fn hello_world() -> &'static str {
    "hello world"
}

fn ja_moin(num: u8) -> i64 {
    if num % 2 == 0 { 0 } else { 1 }
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

    #[test]
    fn test_ja_moin1() {
        assert_eq!(ja_moin(1), 1);
    }

    #[test]
    fn test_ja_moin2() {
        assert_eq!(ja_moin(2), 0);
    }
}
