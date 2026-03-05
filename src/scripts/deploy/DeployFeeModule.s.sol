// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Script } from "lib/forge-std/src/Script.sol";
import { FeeModule } from "src/FeeModule.sol";

/// @dev Minimal interface for CTFExchange role management
interface ICTFExchangeRoles {
    function addOperator(address operator) external;

    function addAdmin(address admin) external;
}

/// @title DeployFeeModule
/// @notice Script to deploy the FeeModule
/// @author Polymarket
contract DeployFeeModule is Script {
    /// @notice Deploys the FeeModule and configures roles on both FeeModule and CTFExchange.
    /// @param admin    - The business admin (Account B)
    /// @param exchange - The CTFExchange address
    function run(address admin, address exchange) public returns (address module) {
        vm.startBroadcast();

        FeeModule feeModule = new FeeModule(exchange);

        // --- FeeModule role setup ---
        // Add admin auth to the Admin address (Account B)
        feeModule.addAdmin(admin);

        // Revoke deployer's auth (Account A)
        feeModule.renounceAdmin();

        module = address(feeModule);

        // --- CTFExchange role setup ---
        // Set FeeModule as operator on CTFExchange, and set Account B as admin on CTFExchange.
        ICTFExchangeRoles(exchange).addOperator(module);
        ICTFExchangeRoles(exchange).addAdmin(admin);

        vm.stopBroadcast();

        if (!_verifyStatePostDeployment(admin, exchange, module)) revert("state verification post deployment failed");
    }

    function _verifyStatePostDeployment(address admin, address exchange, address feeModule)
        internal
        view
        returns (bool)
    {
        FeeModule module = FeeModule(feeModule);

        if (module.isAdmin(msg.sender)) revert("Deployer admin not renounced");
        if (!module.isAdmin(admin)) revert("FeeModule admin not set");
        if (address(module.exchange()) != exchange) revert("Unexpected exchange set on the FeeModule");

        return true;
    }
}
