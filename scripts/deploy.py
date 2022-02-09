from brownie import FundMe, MockV3Aggregator, network, config
from scripts.helpful_scripts import (
    get_account,
    deploy_mocks,
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
)
from web3 import Web3


def deploy_fund_me():
    account = get_account()

    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        price_feed_address = config["networks"][network.show_active()][
            "eth_usd_price_feed"
        ]

    else:
        deploy_mocks()
        price_feed_address = MockV3Aggregator[-1].address

    fund_me = FundMe.deploy(
        price_feed_address,
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify"),
    )
    print(f"Contract deployed to {fund_me.address}")
    return fund_me


def main():
    deploy_fund_me()

    # Verifying the contract on etherscan requires us to copy and paste the
    # contents of this file into the form, but etherscan will not recognise the imports(from chainlink)
    # We'll need to use brownie to create an environment with the api token(created with etherscan account)
    # and then call .deploy with publish_source=True as a parameter
    # Brownie will automatically 'flatten' the contract(remove the imports) and show the user-friendly version of the contract on etherscan
