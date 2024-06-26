def create_bridge_service_config(args, config_artifact, claimtx_keystore_artifact):
    bridge_service_name = "zkevm-bridge-service" + args["deployment_suffix"]
    bridge_service_config = ServiceConfig(
        image=args["zkevm_bridge_service_image"],
        ports={
            "bridge-rpc": PortSpec(
                args["zkevm_bridge_rpc_port"], application_protocol="http"
            ),
            "bridge-grpc": PortSpec(
                args["zkevm_bridge_grpc_port"], application_protocol="grpc"
            ),
        },
        files={
            "/etc/zkevm": Directory(
                artifact_names=[config_artifact, claimtx_keystore_artifact]
            ),
        },
        entrypoint=[
            "/app/zkevm-bridge",
        ],
        cmd=["run", "--cfg", "/etc/zkevm/bridge-config.toml"],
    )
    return {bridge_service_name: bridge_service_config}


def start_bridge_ui(plan, args, config):
    plan.add_service(
        name="zkevm-bridge-ui" + args["deployment_suffix"],
        config=ServiceConfig(
            image=args["zkevm_bridge_ui_image"],
            ports={
                "bridge-ui": PortSpec(
                    args["zkevm_bridge_ui_port"], application_protocol="http"
                ),
            },
            env_vars={
                "ETHEREUM_RPC_URL": "http://{}:{}".format(
                    config.l1_eth_service.ip_address,
                    config.l1_eth_service.ports["rpc"].number,
                ),
                "POLYGON_ZK_EVM_RPC_URL": "http://{}:{}".format(
                    config.zkevm_rpc_ip_address,
                    config.zkevm_rpc_http_port,
                ),
                "BRIDGE_API_URL": "http://{}:{}".format(
                    config.bridge_service_ip_address, config.bridge_api_http_port
                ),
                "ETHEREUM_BRIDGE_CONTRACT_ADDRESS": config.zkevm_bridge_address,
                "POLYGON_ZK_EVM_BRIDGE_CONTRACT_ADDRESS": config.zkevm_bridge_address,
                "ETHEREUM_FORCE_UPDATE_GLOBAL_EXIT_ROOT": "true",
                "ETHEREUM_PROOF_OF_EFFICIENCY_CONTRACT_ADDRESS": config.zkevm_rollup_address,
                "ETHEREUM_ROLLUP_MANAGER_ADDRESS": config.zkevm_rollup_manager_address,
                "ETHEREUM_EXPLORER_URL": args["l1_explorer_url"],
                "POLYGON_ZK_EVM_EXPLORER_URL": args["polygon_zkevm_explorer"],
                "POLYGON_ZK_EVM_NETWORK_ID": "1",
                "ENABLE_FIAT_EXCHANGE_RATES": "false",
                "ENABLE_OUTDATED_NETWORK_MODAL": "false",
                "ENABLE_DEPOSIT_WARNING": "true",
                "ENABLE_REPORT_FORM": "false",
            },
            cmd=["run"],
        ),
    )
