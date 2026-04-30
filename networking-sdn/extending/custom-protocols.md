# Extending with Custom Protocols

This guide shows how to add a new fabric protocol to the system.

## Example: Adding OSPF Support

### 1. Define Protocol Module

Create `fabric/ospf/__init__.py`:
```python
from .ospf import OSPFRouter
__all__ = ['OSPFRouter']
```

### 2. Implement State Machine

Create `fabric/ospf/ospf.py`:
```python
from enum import Enum
from typing import Dict

class OSPFState(Enum):
    DOWN = "DOWN"
    INIT = "INIT"
    TWO_WAY = "TWO_WAY"
    EXCHANGE = "EXCHANGE"
    LOADING = "LOADING"
    FULL = "FULL"

class OSPFRouter:
    def __init__(self, router_id: str, area: str):
        self.router_id = router_id
        self.area = area
        self.neighbors: Dict[str, OSPFState] = {}
```

### 3. Add gRPC Service (Optional)

Extend `controller/api/fabric.proto`:
```protobuf
service FabricAgent {
    // ... existing services
    rpc AdvertiseOSPFRoute(OSPFAdvertisement) returns (RouteStatus);
}

message OSPFAdvertisement {
    string originator = 1;
    string destination = 2;
    int32 cost = 3;
}
```

### 4. Integrate with Controller

Update `controller/pkg/southbound/grpc_server.go`:
```go
func (s *FabricAgentServer) AdvertiseOSPFRoute(ctx context.Context, 
    route *api.OSPFAdvertisement) (*api.RouteStatus, error) {
    // Handle OSPF route
    return &api.RouteStatus{Advertised: true}, nil
}
```

### 5. Test

```bash
cd fabric
python -m pytest ospf/ -v
```

## Adding a New Device Type

Extend `fabric/device/network_device.py`:
```python
class BorderLeafDevice(NetworkDevice):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.external_peers = []
        
    def connect_external_peer(self, peer_addr: str):
        self.external_peers.append(peer_addr)
```

## Tips

- Follow existing module structure (types.py, implementation.py, __init__.py)
- Add comprehensive docstrings
- Include pytest tests (conftest.py + test_*.py)
- Document your protocol in docs/adrs/
