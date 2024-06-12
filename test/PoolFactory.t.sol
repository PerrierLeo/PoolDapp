// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {PoolFactory} from "../src/PoolFactory.sol";
import {Pool} from "../src/Pool.sol";

contract PoolFactoryTest is Test {
    PoolFactory public poolFactory;

    address contribuer1 = makeAddr("user1");
    address contribuer2 = makeAddr("user2");

    function setUp() public {
        vm.prank(contribuer1);
        poolFactory = new PoolFactory();
    }

    function test_createPool() public {
        vm.prank(contribuer1);
        Pool pool = poolFactory.createPool(4 weeks, 10 ether);
        assertEq(contribuer1, pool.leOwner());
    }
}
