// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Pool} from "../src/Pool.sol";

contract PoolTest is Test {
    Pool public pool;

    address owner = makeAddr("user0");
    address contribuer1 = makeAddr("user1");
    address contribuer2 = makeAddr("user2");
    address contribuer3 = makeAddr("user3");

    uint256 end = 4 weeks;
    uint256 duration = 1 weeks;
    uint256 goal = 10 ether;

    function setUp() public {
        vm.prank(owner);
        pool = new Pool(duration, goal);
    }

    function test_SetUpState() public view {
        assertEq(pool.owner(), owner);
        assertEq(pool.goal(), goal);
        assertEq(pool.end(), (block.timestamp + duration));
    }

    function test_RevertWhen_EndIsReached() public {
        //conf
        vm.warp(pool.end() + 3600);

        //Expected error
        bytes4 selector = bytes4(keccak256("CollectIsFinished()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        //contribute
        hoax(contribuer1, 1 ether);
        pool.contribute{value: 1 ether}();
    }

    function test_RevertWhen_NotEnoughFound() public {
        //Expected error
        bytes4 selector = bytes4(keccak256("NotEnoughFund()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        //contribute
        vm.prank(contribuer1);
        pool.contribute();
    }

    function test_RevertWhen_GoalIsReached(uint96 _amount) public {
        //conf
        vm.assume(_amount > 10 ether);
        hoax(contribuer1, _amount);
        pool.contribute{value: _amount}();

        //Expected error
        bytes4 selector = bytes4(keccak256("GoalAlreadyReached()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        //contribute
        pool.contribute();
    }

    function test_ExpectEmit_SuccessFullContribute(uint96 _amount) public {
        vm.assume(_amount > 0);
        vm.expectEmit(true, false, false, true);
        emit Pool.Contribute(contribuer1, _amount);
        hoax(contribuer1, _amount);
        pool.contribute{value: _amount}();
    }

    // function test_ContributionAddition() public {
    //     hoax(contribuer1, 60 ether);
    //     pool.contribute{value: 20 ether}();
    //     assertEq(pool.contributions(contribuer1), 20 ether);
    //     pool.contribute{value: 20 ether}();
    //     assertEq(pool.contributions(contribuer1), 40);
    // }

    function test_RevertWhenNotOwner() public {
        bytes4 selector = bytes4(
            keccak256("OwnableUnauthorizedAccount(address)")
        );
        vm.expectRevert(abi.encodeWithSelector(selector, contribuer1));

        vm.prank(contribuer1);
        pool.withdraw();
    }

    function test_RevertWhen_EndIsNotReached() public {
        //conf
        vm.prank(owner);

        //Expected error
        bytes4 selector = bytes4(keccak256("CollectNotFinished()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        //contribute
        pool.withdraw();
    }

    function test_RevertWhen_WithdrawFailedToSendEther() public {
        pool = new Pool(duration, goal);

        hoax(owner, 10 ether);
        pool.contribute{value: 10 ether}();

        vm.warp(pool.end() + 3600);

        //Expected error
        bytes4 selector = bytes4(keccak256("FailedToSendEther()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        pool.withdraw();
    }

    function test_withdraw() public {
        hoax(contribuer1, 10 ether);
        pool.contribute{value: 10 ether}();
        vm.warp(pool.end() + 3600);

        vm.prank(owner);
        pool.withdraw();
    }

    function test_RevertWhen_CollectNotFinished() public {
        //Expected error
        bytes4 selector = bytes4(keccak256("CollectNotFinished()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        pool.refund();
    }

    function test_RevertWhen_GoalAlreadyReached() public {
        //conf
        hoax(contribuer1, 10 ether);
        pool.contribute{value: 10 ether}();
        vm.warp(pool.end() + 3600);

        //Expected error
        bytes4 selector = bytes4(keccak256("GoalAlreadyReached()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        pool.refund();
    }

    function test_RevertWhen_NoContribution() public {
        //conf
        hoax(contribuer1);
        vm.warp(pool.end() + 3600);

        //Expected error
        bytes4 selector = bytes4(keccak256("NoContribution()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        pool.refund();
    }

    function test_RevertWhen_RefundFailedToSendEther() public {
        //conf
        hoax(address(this), 2 ether);
        pool.contribute{value: 2 ether}();
        vm.warp(pool.end() + 3600);

        //Expected error
        bytes4 selector = bytes4(keccak256("FailedToSendEther()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        pool.refund();
    }

    function test_refund() public {
        hoax(contribuer1, 2 ether);
        uint256 beforeRefund = contribuer1.balance;
        pool.contribute{value: 2 ether}();
        vm.warp(pool.end() + 3600);
        vm.prank(contribuer1);
        pool.refund();
        uint256 afterRefund = contribuer1.balance;
        assertEq(beforeRefund, afterRefund);
    }
}
