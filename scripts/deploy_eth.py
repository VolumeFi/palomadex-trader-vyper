from ape import accounts, project, networks


def main():
    acct = accounts.load("deployer_account")
    compass = "0x71956340a586db3afD10C2645Dbe8d065dD79AC8"
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

# 0x656D519E4ca6516e868D2912C614C9c0294b632e
# 0xDf8b08ccD625391E744680A3DB91a7ff5017A1E8
# 0x7230EC05eD8c38D5be6f58Ae41e30D1ED6cfDAf1