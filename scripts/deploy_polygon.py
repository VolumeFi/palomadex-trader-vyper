from ape import accounts, project, networks


def main():
    acct = accounts.load("deployer_account")
    compass = "0x6aC565F13FEE0f5D44D76036Aa6461Fb1A9D8b4B"
    service_fee_collector = "0x9cf40152d7fb47dff8ad199282b002ca312ec818"
    refund_wallet = "0x6dc0A87638CD75Cc700cCdB226c7ab6C054bc70b"
    service_fee = 10 ** 16
    gas_fee = 10 ** 17

    priority_fee = int(networks.active_provider.priority_fee * 1.2)
    base_fee = int(networks.active_provider.base_fee * 1.2 + priority_fee)
    trader = project.trader.deploy(
        compass, refund_wallet, gas_fee, service_fee_collector, service_fee,
        max_fee=base_fee, max_priority_fee=priority_fee, sender=acct)

    print(trader)

# 0x3E1Cc0a7d41E4945B376650eAa34498e65E5D327
