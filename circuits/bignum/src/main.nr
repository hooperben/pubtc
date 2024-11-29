global UINT_32_MAX = 4294967295;
global SIMPLE_8er = 8;

type Uint256 = [u32; SIMPLE_8er];

fn add(x: Uint256, y: Uint256) -> Uint256 {
    let mut result: Uint256 = [0; 8];
    let mut carry: u32 = 0;

    for i in 0..8 {
        let sum = x[i] + y[i];

        result[i] = sum;
    }

    result
}

fn main() {
    let one: Uint256 = [0,0,0,0,0,0,1,0];
    let two: Uint256 = [0,0,0,0,0,0,0,4294967295];

    let result = add(one, two);
    println(result);
}

#[test]
fn test_main() {
    main();
}