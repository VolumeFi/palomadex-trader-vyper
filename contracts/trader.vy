#pragma version 0.4.1
#pragma optimize gas
#pragma evm-version cancun
"""
@title Palomadex Trader
@license Apache 2.0
@author Volume.finance
"""

interface ERC20:
    def balanceOf(_owner: address) -> uint256: view
    def approve(_spender: address, _value: uint256) -> bool: nonpayable
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable

interface Compass:
    def send_token_to_paloma(token: address, receiver: bytes32, amount: uint256): nonpayable
    def slc_switch() -> bool: view

DENOMINATOR: constant(uint256) = 10 ** 18

event Purchase:
    sender: indexed(address)
    from_token: address
    to_token: address
    amount: uint256
    paloma: bytes32

event AddLiquidity:
    sender: indexed(address)
    token0: address
    token1: address
    amount0: uint256
    amount1: uint256

event RemoveLiquidity:
    sender: indexed(address)
    token0: address
    token1: address
    amount: uint256

event TokenSent:
    token: address
    to: address
    amount: uint256
    nonce: uint256

event UpdateCompass:
    old_compass: address
    new_compass: address

event UpdateRefundWallet:
    old_refund_wallet: address
    new_refund_wallet: address

event SetPaloma:
    paloma: bytes32

event UpdateGasFee:
    old_gas_fee: uint256
    new_gas_fee: uint256

event UpdateServiceFeeCollector:
    old_service_fee_collector: address
    new_service_fee_collector: address

event UpdateServiceFee:
    old_service_fee: uint256
    new_service_fee: uint256

compass: public(address)
refund_wallet: public(address)
gas_fee: public(uint256)
service_fee_collector: public(address)
service_fee: public(uint256)
paloma: public(bytes32)
send_nonces: public(HashMap[uint256, bool])

@deploy
def __init__(_compass: address, _refund_wallet: address, _gas_fee: uint256, _service_fee_collector: address, _service_fee: uint256):
    self.compass = _compass
    self.refund_wallet = _refund_wallet
    self.gas_fee = _gas_fee
    self.service_fee_collector = _service_fee_collector
    self.service_fee = _service_fee
    log UpdateCompass(old_compass=empty(address), new_compass=_compass)
    log UpdateRefundWallet(old_refund_wallet=empty(address), new_refund_wallet=_refund_wallet)
    log UpdateGasFee(old_gas_fee=0, new_gas_fee=_gas_fee)
    log UpdateServiceFeeCollector(old_service_fee_collector=empty(address), new_service_fee_collector=_service_fee_collector)
    log UpdateServiceFee(old_service_fee=0, new_service_fee=_service_fee)

@internal
def _safe_approve(_token: address, _to: address, _value: uint256):
    assert extcall ERC20(_token).approve(_to, _value, default_return_value=True), "Failed approve"

@internal
def _safe_transfer(_token: address, _to: address, _value: uint256):
    assert extcall ERC20(_token).transfer(_to, _value, default_return_value=True), "Failed transfer"

@internal
def _safe_transfer_from(_token: address, _from: address, _to: address, _value: uint256):
    assert extcall ERC20(_token).transferFrom(_from, _to, _value, default_return_value=True), "Failed transferFrom"

@internal
def _paloma_check():
    assert msg.sender == self.compass, "Not compass"
    assert self.paloma == convert(slice(msg.data, unsafe_sub(len(msg.data), 32), 32), bytes32), "Invalid paloma"

@external
@payable
@nonreentrant
def purchase(from_token: address, to_token: address, amount: uint256):
    assert from_token != empty(address), "Invalid from_token"
    assert to_token != empty(address), "Invalid to_token"
    assert amount > 0, "Invalid amount"
    _value: uint256 = msg.value
    _gas_fee: uint256 = self.gas_fee
    if _gas_fee > 0:
        _value -= _gas_fee
        send(self.refund_wallet, _gas_fee)
    if _value > 0:
        send(msg.sender, _value)
    _amount: uint256 = staticcall ERC20(from_token).balanceOf(self)
    self._safe_transfer_from(from_token, msg.sender, self, amount)
    _amount = staticcall ERC20(from_token).balanceOf(self) - _amount
    _paloma: bytes32 = self.paloma
    _service_fee: uint256 = self.service_fee
    if _service_fee > 0:
        _service_fee_collector: address = self.service_fee_collector
        _service_fee_amount: uint256 = _amount * _service_fee // DENOMINATOR
        self._safe_transfer(from_token, _service_fee_collector, _service_fee_amount)
        _amount -= _service_fee_amount
    _compass: address = self.compass
    self._safe_approve(from_token, _compass, _amount)
    extcall Compass(self.compass).send_token_to_paloma(from_token, _paloma, _amount)
    log Purchase(sender=msg.sender, from_token=from_token, to_token=to_token, amount=_amount, paloma=_paloma)

@external
@payable
@nonreentrant
def add_liquidity(token0: address, token1: address, amount0: uint256, amount1: uint256):
    assert token0 != empty(address), "Invalid token0"
    assert token1 != empty(address), "Invalid token1"
    assert token0 != token1, "Invalid token0 and token1"
    assert amount0 > 0, "Invalid amount0"
    assert amount1 > 0, "Invalid amount1"
    _value: uint256 = msg.value
    _gas_fee: uint256 = self.gas_fee
    if _gas_fee > 0:
        _value -= _gas_fee
        send(self.refund_wallet, _gas_fee)
    if _value > 0:
        send(msg.sender, _value)
    _amount0: uint256 = staticcall ERC20(token0).balanceOf(self)
    _amount1: uint256 = staticcall ERC20(token1).balanceOf(self)
    self._safe_transfer_from(token0, msg.sender, self, amount0)
    self._safe_transfer_from(token1, msg.sender, self, amount1)
    _amount0 = staticcall ERC20(token0).balanceOf(self) - _amount0
    _amount1 = staticcall ERC20(token1).balanceOf(self) - _amount1
    _compass: address = self.compass
    self._safe_approve(token0, _compass, _amount0)
    self._safe_approve(token1, _compass, _amount1)
    extcall Compass(_compass).send_token_to_paloma(token0, self.paloma, _amount0)
    extcall Compass(_compass).send_token_to_paloma(token1, self.paloma, _amount1)
    log AddLiquidity(sender=msg.sender, token0=token0, token1=token1, amount0=_amount0, amount1=_amount1)

@external
@payable
@nonreentrant
def remove_liquidity(token0: address, token1: address, amount: uint256):
    _value: uint256 = msg.value
    _gas_fee: uint256 = self.gas_fee
    if _gas_fee > 0:
        _value -= _gas_fee
        send(self.refund_wallet, _gas_fee)
    if _value > 0:
        send(msg.sender, _value)
    log RemoveLiquidity(sender=msg.sender, token0=token0, token1=token1, amount=amount)

@external
@nonreentrant
def send_token(tokens: DynArray[address, 2], to: address, amounts: DynArray[uint256, 2], nonce: uint256):
    self._paloma_check()
    assert not self.send_nonces[nonce], "Invalid nonce"
    assert len(tokens) == len(amounts), "Invalid tokens and amounts"
    i: uint256 = 0
    for token: address in tokens:
        if token == empty(address):
            raw_call(to, b"", value=amounts[i])
        else:
            self._safe_transfer(token, to, amounts[i])
        log TokenSent(token, to, amounts[i], nonce)
        i += 1
    self.send_nonces[nonce] = True

@external
def update_compass(new_compass: address):
    _compass: address = self.compass
    assert msg.sender == _compass, "Not compass"
    assert not staticcall Compass(_compass).slc_switch(), "SLC is unavailable"
    self.compass = new_compass
    log UpdateCompass(old_compass=msg.sender, new_compass=new_compass)

@external
def set_paloma():
    assert msg.sender == self.compass and self.paloma == empty(bytes32) and len(msg.data) == 36, "Invalid"
    _paloma: bytes32 = convert(slice(msg.data, 4, 32), bytes32)
    self.paloma = _paloma
    log SetPaloma(paloma=_paloma)

@external
def update_refund_wallet(new_refund_wallet: address):
    self._paloma_check()
    old_refund_wallet: address = self.refund_wallet
    self.refund_wallet = new_refund_wallet
    log UpdateRefundWallet(old_refund_wallet=old_refund_wallet, new_refund_wallet=new_refund_wallet)

@external
def update_gas_fee(new_gas_fee: uint256):
    self._paloma_check()
    old_gas_fee: uint256 = self.gas_fee
    self.gas_fee = new_gas_fee
    log UpdateGasFee(old_gas_fee=old_gas_fee, new_gas_fee=new_gas_fee)

@external
def update_service_fee_collector(new_service_fee_collector: address):
    self._paloma_check()
    old_service_fee_collector: address = self.service_fee_collector
    self.service_fee_collector = new_service_fee_collector
    log UpdateServiceFeeCollector(old_service_fee_collector=old_service_fee_collector, new_service_fee_collector=new_service_fee_collector)

@external
def update_service_fee(new_service_fee: uint256):
    self._paloma_check()
    assert new_service_fee < DENOMINATOR, "Invalid service fee"
    old_service_fee: uint256 = self.service_fee
    self.service_fee = new_service_fee
    log UpdateServiceFee(old_service_fee=old_service_fee, new_service_fee=new_service_fee)

@external
@payable
def __default__():
    pass