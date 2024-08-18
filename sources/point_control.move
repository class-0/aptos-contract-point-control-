module point_addr::point_control {
    use aptos_framework::coin::{Self, Coin};
    use std::signer;

    use aptos_std::debug;
    use aptos_framework::timestamp;
    use aptos_framework::aptos_coin::AptosCoin;

    const ERR_NOT_OWNER: u64 = 1;

    const ERR_NOT_INITIALIZED: u64 = 2;
    
    const ERR_NOT_OPERATOR: u64 = 3;

    const ERR_LOCKED_PERIOD: u64 = 4;

    const ERR_INSUFFICIENT_BALANCE: u64 = 5;

    struct Point has key {
        fee: u64,
        points: u64,
        operator: address,
        timestamp: u64,
        owner: address,
        coin: Coin<AptosCoin>,
    }

    public entry fun initialize(owner_admin: &signer, operator: address, fee: u64) {
        debug::print_stack_trace();
        let addr = signer::address_of(owner_admin);

        assert!(addr == @point_addr, ERR_NOT_OWNER);

        move_to(owner_admin, Point {
            fee: fee,
            points: 0,
            owner: addr,
            operator: operator,
            timestamp: 0,
            coin: coin::zero<AptosCoin>()
        });
    }

    public fun assert_is_owner(addr: address) acquires Point {
        let owner = borrow_global<Point>(@point_addr).owner;
        assert!(addr == owner, ERR_NOT_OWNER);
    }

    public fun assert_is_operator(addr: address) acquires Point {
        let operator = borrow_global<Point>(@point_addr).operator;
        assert!(addr == operator, ERR_NOT_OPERATOR);
    }

    public fun assert_is_initialized() {
        assert!(exists<Point>(@point_addr), ERR_NOT_INITIALIZED);
    }

    public entry fun set_fee(acc: &signer, value: u64) acquires Point {
        let addr = signer::address_of(acc);

        assert_is_initialized();
        assert_is_owner(addr);

        let fee = &mut borrow_global_mut<Point>(@point_addr).fee;

        *fee = value;
    }

    public entry fun set_operator(acc: &signer, oper: address) acquires Point {
        let addr = signer::address_of(acc);

        assert_is_initialized();
        assert_is_owner(addr);

        let operator = &mut borrow_global_mut<Point>(@point_addr).operator;

        *operator = oper;
    }

    public entry fun increase(acc: &signer) acquires Point {
        let addr = signer::address_of(acc);

        assert_is_initialized();
        assert_is_operator(addr);
        let point = borrow_global_mut<Point>(@point_addr);
        assert!(coin::balance<AptosCoin>(addr) >= point.fee, ERR_INSUFFICIENT_BALANCE);

        let coin = coin::withdraw<AptosCoin>(acc, point.fee);
        coin::deposit(point.owner, coin);
        let cur_timestamp = timestamp::now_microseconds();
        assert!(point.timestamp + 24 * 60 * 60 * 1000 < cur_timestamp , ERR_LOCKED_PERIOD);

        *(&mut point.timestamp) = cur_timestamp;
        *(&mut point.points) = point.points + 1;
    }

     #[view]
    public fun point(): u64 acquires Point {
        assert_is_initialized();

        borrow_global<Point>(@point_addr).points
    }
}
