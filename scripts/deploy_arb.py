from ape import accounts, project, networks


def main():
    acct = accounts.load("deployer_account")
    compass = "0x3c1864a873879139C1BD87c7D95c4e475A91d19C"
    service_fee_collector = "0x9cf40152d7fb47dff8ad199282b002ca312ec818"
    refund_wallet = "0x6dc0A87638CD75Cc700cCdB226c7ab6C054bc70b"
    service_fee = 10 ** 16
    gas_fee = 5 * 10 ** 13
    
    priority_fee = int(networks.active_provider.priority_fee * 1.2)
    base_fee = int(networks.active_provider.base_fee * 1.2 + priority_fee)
    trader = project.trader.deploy(
        compass, refund_wallet, gas_fee, service_fee_collector, service_fee,
        max_fee=base_fee, max_priority_fee=priority_fee,  sender=acct)

    print(trader)

# 0xdb191394bac615D4b5Dfeb917890dA55c4470247
# 0x5bb5B00C2226927C0092fe9D3f787EBb93dcfcdd
# 0x36B8763b3b71685F21512511bB433f4A0f50213E
