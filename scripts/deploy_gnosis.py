from ape import accounts, project, networks


def main():
    acct = accounts.load("deployer_account")
    compass = "0xc2A1a1bD4018cFAA744dD5Fb9D0c06f460e1C63A"
    service_fee_collector = "0x9cf40152d7fb47dff8ad199282b002ca312ec818"
    refund_wallet = "0x6dc0A87638CD75Cc700cCdB226c7ab6C054bc70b"
    service_fee = 10 ** 16
    gas_fee = 3 * 10 ** 15

    priority_fee = int(networks.active_provider.priority_fee * 1.2)
    base_fee = int(networks.active_provider.base_fee * 1.2 + priority_fee)
    trader = project.trader.deploy(
        compass, refund_wallet, gas_fee, service_fee_collector, service_fee,
        max_fee=base_fee, max_priority_fee=priority_fee, sender=acct)

    print(trader)

# 0x96005928AF42e94b5012B32C858855765985F726
# 0xB6d4AAFfBbceB5e363352179E294326C91d6c127
# 0xd58Dfd5b39fCe87dD9C434e95428DdB289934179