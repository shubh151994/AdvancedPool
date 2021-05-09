# @version 0.2.4

interface LiquidityGauge:
    # Presumably, other gauges will provide the same interfaces
    def integrate_fraction(addr: address) -> uint256: view
    def user_checkpoint(addr: address) -> bool: nonpayable

interface MERC20:
    def mint(_to: address, _value: uint256) -> bool: nonpayable

interface GaugeController:
    def gauge_types(addr: address) -> int128: view

event Minted:
    recipient: indexed(address)
    gauge: address
    minted: uint256

token: public(address)

@external
def __init__(_token: address):
    self.token = _token

@external
@nonreentrant('lock')
def mint(gauge_addr: address):
    MERC20(self.token).mint(msg.sender, 100000000000000000000)

@external
def updatetoken(_token: address):
    self.token = _token