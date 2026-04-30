# Adding Device Types

This guide explains how to add new device types and roles to the fabric.

## Device Architecture

All devices inherit from `NetworkDevice`:
```python
from fabric.device import NetworkDevice, DeviceRole

class CustomDevice(NetworkDevice):
    def __init__(self, device_id: str, asn: int, router_id: str, 
                 role: DeviceRole, mgmt_ip: str):
        super().__init__(device_id, asn, router_id, role, mgmt_ip)
        # Custom initialization
```

## Example: Firewall Device

```python
class FirewallDevice(NetworkDevice):
    def __init__(self, device_id: str, asn: int, router_id: str, mgmt_ip: str):
        super().__init__(device_id, asn, router_id, DeviceRole.BORDER, mgmt_ip)
        self.security_policies = []
        self.sessions = {}
        
    def add_security_policy(self, policy: dict):
        self.security_policies.append(policy)
        
    def forward_packet(self, dest_ip: str) -> bool:
        # Check security policies before forwarding
        for policy in self.security_policies:
            if self._matches_policy(dest_ip, policy):
                if policy['action'] == 'deny':
                    self.packets_dropped += 1
                    return False
        return super().forward_packet(dest_ip)
```

## Registering Device with Controller

Use the gRPC API:
```python
from grpc import channel
from controller.api import fabric_pb2

# Create gRPC client
chan = channel.secure_channel('controller:9090', ...)
stub = fabric_pb2.FabricAgentStub(chan)

# Register device
response = stub.RegisterDevice(fabric_pb2.DeviceInfo(
    device_id='fw1',
    device_addr='10.0.0.1',
    device_role='border'
))
```

## Adding to Lab

Update `lab/scripts/register-devices.sh`:
```bash
# Register firewall device
curl -X POST "$CONTROLLER_URL/api/v1/devices/register" \
    -H "Content-Type: application/json" \
    -d '{"device_id":"fw1","address":"10.0.0.1","role":"border"}'
```

## Testing Device Behavior

```python
import pytest
from fabric.device import NetworkDevice, DeviceRole

def test_custom_device():
    dev = CustomDevice('dev1', 65000, '1.1.1.1', DeviceRole.LEAF, '10.0.0.1')
    
    # Add interface
    dev.add_interface('eth0', '10.1.1.1')
    assert 'eth0' in dev.interfaces
    
    # Add route
    dev.add_route('10.2.0.0/16', '10.1.1.254')
    assert '10.2.0.0/16' in dev.routing_table
    
    # Forward packet
    assert dev.forward_packet('10.2.1.100') == True
    assert dev.packets_forwarded == 1
```

## Protocol Integration

Once your device is registered, it can:
1. Join BGP peer group
2. Create VXLAN tunnels
3. Learn/advertise routes
4. Send/receive EVPN updates
5. Participate in policies

See [Custom Protocols](custom-protocols.md) for protocol implementation.
