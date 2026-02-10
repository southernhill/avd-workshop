# AVD Workshop — Lab Guide

> Complete all steps in the [README](../README.md) before starting.

---

## Exercise 1: Orientation — Project Structure & Build Pipeline

**Goal:** Understand how the project files link together and what AVD generates from them.

### Explore the project

Read through each file and its comments. Pay attention to how they reference each other:

```text
group_vars/
├── FABRIC/
│   ├── fabric.yml       ← fabric_name — must match the top-level inventory group
│   └── ansible.yml      ← connection settings, mgmt network, local user
├── SPINES.yml           ← type: spine — links SPINES group to the 'spine' key
└── LEAVES.yml           ← type: l3leaf — links LEAVES group to the 'l3leaf' key
```

Start with these files in order:

1. **`inventory.yml`** — the device inventory. Note the group hierarchy: `FABRIC` → `SPINES` + `LEAVES` → individual hosts.
2. **`group_vars/FABRIC/fabric.yml`** — just `fabric_name: FABRIC`. This tells AVD which inventory group is the top-level fabric. Everything in `group_vars/FABRIC/` is loaded for all hosts in this group.
3. **`group_vars/FABRIC/ansible.yml`** — how Ansible connects (eAPI over HTTPS), management network settings, and the local user account AVD generates on every switch.
4. **`group_vars/SPINES.yml`** — sets `type: spine` so AVD uses the `spine` key for these hosts. Contains the spine topology: BGP AS, loopback pool, node list.
5. **`group_vars/LEAVES.yml`** — sets `type: l3leaf` so AVD uses the `l3leaf` key for these hosts. Contains the leaf topology: uplink definitions, IP pools, node groups with per-rack BGP AS.
6. **`clab/topology.clab.yaml`** — the containerlab topology that mirrors the inventory. This is the virtual network you'll deploy to.

### Build and inspect

```bash
make build
```

The topology is already defined, so AVD generates full configs. Compare the input to the output:

- **Input:** `SPINES.yml` + `LEAVES.yml` (~50 lines of topology YAML total)
- **Intermediate:** `intended/structured_configs/leaf-01.yml` (hundreds of lines of structured data)
- **Output:** `intended/configs/leaf-01.cfg` (complete EOS running config)

Look at how AVD auto-generates from those ~50 lines:

- BGP underlay + overlay peering
- Loopback and P2P link IP addressing
- VXLAN interface
- Route maps and prefix lists
- Interface descriptions

Note the difference between spine configs (BGP underlay + EVPN route-server) and leaf configs (BGP + VXLAN + VRFs).

### Deploy and verify

```bash
make twin
```

SSH into the switches and confirm the fabric is healthy:

```bash
ssh spine-01
```

```text
show ip bgp summary
show bgp evpn summary
```

```bash
ssh leaf-01
```

```text
show interfaces vxlan 1
show ip bgp summary
```

You should see established BGP peers on the spines and a VXLAN interface on the leaves. All of this was generated from the topology YAML — no manual config.

---

## Exercise 2: Base Config — NTP, DNS, Timezone

**Goal:** Add basic device settings and experience the YAML → build → deploy → verify cycle.

### 1. Edit the data model

Open `group_vars/FABRIC/fabric.yml` and add NTP, DNS, and timezone settings.

Use the AVD documentation to find the right keys. The docs page is long — use your browser's find tool (Cmd+F / Ctrl+F) to search for the key names:

- **NTP** — search for `ntp_settings` in the [eos_designs](https://avd.arista.com/5.7/ansible_collections/arista/avd/roles/eos_designs/docs/input-variables.html) docs. Add a server entry.
- **DNS** — search for `dns_settings` in the same page. Add servers with their VRF.
- **Timezone** — search for `timezone` in the same page.

Here are the values to use:

| Setting | Value |
| --- | --- |
| NTP server | nl.pool.ntp.org |
| DNS servers | 8.8.8.8, 1.1.1.1 (both in VRF mgmt) |
| Timezone | Europe/Amsterdam |

<details>
<summary>Show answer</summary>

```yaml
---
fabric_name: FABRIC

ntp_settings:
  servers:
    - name: nl.pool.ntp.org

dns_settings:
  servers:
    - vrf: use_default_mgmt_method_vrf
      ip_address: 8.8.8.8
    - vrf: use_default_mgmt_method_vrf
      ip_address: 1.1.1.1

timezone: Europe/Amsterdam
```

</details>

### 2. Build and deploy

```bash
make build
make twin
```

### 3. Verify

SSH into any switch and confirm the settings are applied:

```bash
ssh spine-01
```

```text
show ntp status
show ip name-server
show clock
```

NTP can take a few minutes to synchronize — if `show ntp status` says "unsynchronised", check `show ntp associations` to confirm the server is being polled, then move on and check back later. You should also see DNS resolvers listed and the correct timezone.

---

## Exercise 3: Network Services — VRF + VLANs

**Goal:** Create the network services data model from scratch — add a tenant, VRF, and VLANs with SVIs.

### 1. Create the file

Create a new file `group_vars/FABRIC/network_services.yml` with the following content:

```yaml
---
tenants:
  - name: WORKSHOP_TENANT
    mac_vrf_vni_base: 10000
    vrfs:
      - name: VRF_A
        vrf_vni: 10
        svis:
          - id: 110
            name: Servers_110
            enabled: true
            ip_address_virtual: 10.110.110.1/24
          - id: 120
            name: Servers_120
            enabled: true
            ip_address_virtual: 10.120.120.1/24
```

### 2. Build and inspect

```bash
make build
```

Look at the leaf configs again. You should see new sections for:

- VRF `VRF_A` with VNI 10
- VLANs 110 and 120 with their VXLAN VNI mappings (10110, 10120)
- SVIs with the virtual IP addresses
- EVPN instance updated with the new VRF

### 3. Deploy and verify

```bash
make twin
```

SSH into a leaf and confirm:

```bash
ssh leaf-01
```

```text
show vxlan vni
show ip route vrf VRF_A
show interfaces vxlan 1
```

You should see VNI-to-VLAN mappings and connected routes for both subnets in VRF_A.

---

## Exercise 4: Change Workflow — Add VLAN 130

**Goal:** Walk through the full change lifecycle: edit YAML, build, preview, deploy, verify.

### 1. Add VLAN 130

Open `group_vars/FABRIC/network_services.yml` and add a new SVI under VRF_A:

```yaml
          - id: 130
            name: Database_130
            enabled: true
            ip_address_virtual: 10.130.130.1/24
```

### 2. Build, preview, deploy

```bash
make build
make preview    # only leaf configs should show changes
make twin
```

### 3. Verify the new VLAN

SSH into a leaf and confirm VLAN 130 is present with the correct VNI mapping and SVI.

---

## Exercise 5: Git Workflow

**Goal:** Use feature branches for network changes — the same workflow used in production.

### 1. Commit your work so far

Before branching, save everything you've done in exercises 2–4
on main. This keeps the feature branch clean — it will only
contain the VLAN 140 change.

```bash
git add -A
git commit -m "add NTP, DNS, timezone, and network services"
```

### 2. Create a feature branch

```bash
git checkout -b feature/add-vlan-140
```

### 3. Make a change

Add VLAN 140 to `network_services.yml`:

```yaml
          - id: 140
            name: Management_140
            enabled: true
            ip_address_virtual: 10.140.140.1/24
```

### 4. Build and commit

```bash
make build
git add -A
git commit -m "add VLAN 140 for management network"
```

### 5. Review the history

```bash
git log --oneline --all --graph
```

In production: push the branch, open a PR, CI runs `make build` automatically, the team reviews the YAML diff + generated config diff, then merge triggers deployment.

---

## Bonus: Add a Second VRF

**Goal:** Extend the fabric with a new VRF and its own set of VLANs — this requires understanding how AVD maps tenants, VRFs, and SVIs.

### 1. Add VRF_B to the data model

Edit `group_vars/FABRIC/network_services.yml` and add a second VRF under the existing tenant:

```yaml
      - name: VRF_B
        vrf_vni: 20
        svis:
          - id: 210
            name: IoT_210
            enabled: true
            ip_address_virtual: 10.210.210.1/24
          - id: 220
            name: Security_220
            enabled: true
            ip_address_virtual: 10.220.220.1/24
```

### 2. Build and inspect the new VRF

```bash
make build
```

Look at the generated leaf configs. You should see:

- A new VRF `VRF_B` with VNI 20
- VLANs 210 and 220 with their VNI mappings (10210, 10220)
- New SVIs with the virtual IPs
- The EVPN instance updated with the new VRF

### 3. Deploy and verify both VRFs

```bash
make twin
```

SSH into a leaf and confirm:

- `show vrf` — both VRF_A and VRF_B present
- `show vxlan vni` — VNIs for both VRFs and all VLANs
- `show ip route vrf VRF_B` — connected routes for the new subnets
- Confirm VRF_A is unaffected

---

## The daily workflow

```text
1. git checkout -b feature/my-change
2. Edit YAML in group_vars/
3. make build
4. make preview
5. make twin          (test on digital twin)
6. Verify on switches
7. git add && git commit
8. Push + create PR
9. Team review + CI
10. Merge → deploy
```
