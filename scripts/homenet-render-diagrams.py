#!/usr/bin/env python3
"""Render logical and physical UniFi network diagrams from a snapshot JSON.

Inputs:
  argv[1]: path to snapshot JSON produced by the network-architect (Phase 1)
  argv[2]: output directory (typically HomeNetwork/diagrams/)

Outputs (SVG and PNG each):
  <out>/logical-network.{svg,png}   VLAN/SSID/zone view
  <out>/physical-topology.{svg,png} gateway -> APs/switches -> clients

Requires:
  pip3 install diagrams
  brew install graphviz

The mingrammer/diagrams library does not ship Ubiquiti icons. The on-prem.network
namespace (Cisco icons) is used as a stand-in for visual clarity. To swap in
Ubiquiti icons later, drop SVGs into ~/.claude/assets/ubiquiti-icons/ and replace
the node classes below with diagrams.custom.Custom(label, icon_path).
"""
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


def die(msg: str, code: int = 1) -> None:
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(code)


def load_snapshot(path: Path) -> dict[str, Any]:
    if not path.exists():
        die(f"snapshot not found: {path}")
    with path.open() as f:
        return json.load(f)


def safe_get(d: dict, *keys, default=None):
    for k in keys:
        if not isinstance(d, dict) or k not in d:
            return default
        d = d[k]
    return d


def render_logical(snapshot: dict, out_base: Path) -> None:
    from diagrams import Cluster, Diagram, Edge
    from diagrams.generic.network import Firewall, Router, Switch
    from diagrams.generic.device import Mobile, Tablet
    from diagrams.onprem.client import Client, User
    from diagrams.generic.network import Subnet

    cats = snapshot.get("categories", {})
    networks = cats.get("networks") or []
    wlans = cats.get("wlans") or []
    zones = cats.get("zbf_zones") or []
    sysinfo = cats.get("system_info") or {}

    controller = sysinfo.get("hostname") or sysinfo.get("name") or "UDM Pro"

    # diagrams library writes to cwd by default. Use outformat per file.
    for fmt in ("svg", "png"):
        with Diagram(
            "Logical Network",
            filename=str(out_base.with_suffix("")),
            outformat=fmt,
            show=False,
            direction="TB",
            graph_attr={"fontsize": "16", "bgcolor": "white", "pad": "0.5"},
        ):
            internet = Router("Internet (WAN)")
            gateway = Firewall(controller)
            internet >> gateway

            # One cluster per VLAN; SSIDs and zone membership inside.
            vlan_clusters = {}
            for net in networks:
                if not isinstance(net, dict):
                    continue
                vlan_id = net.get("vlan") or net.get("vlan_id") or 1
                name = net.get("name") or f"VLAN {vlan_id}"
                subnet = net.get("ip_subnet") or net.get("subnet") or ""
                purpose = net.get("purpose") or ""
                label = f"{name}\nVLAN {vlan_id}\n{subnet}\n({purpose})"
                with Cluster(label):
                    vlan_node = Subnet(name)
                    gateway >> Edge(label=str(vlan_id)) >> vlan_node
                    vlan_clusters[net.get("_id") or net.get("id") or name] = vlan_node

                    # Hang SSIDs off their network
                    for w in wlans:
                        if not isinstance(w, dict):
                            continue
                        nc = w.get("networkconf_id")
                        if nc and nc == (net.get("_id") or net.get("id")):
                            sec = w.get("security") or "?"
                            wlabel = f"SSID: {w.get('name','?')}\n{sec}"
                            Mobile(wlabel) - Edge(style="dotted") - vlan_node

            # Firewall zones overlay (if any)
            if zones:
                with Cluster("Firewall Zones"):
                    for z in zones:
                        if not isinstance(z, dict):
                            continue
                        Switch(z.get("name") or z.get("zone_name") or "zone")
        # diagrams library appends extension to filename param. Move it to target.
        # The Diagram() call already wrote out_base.with_suffix('').<fmt>


def render_physical(snapshot: dict, out_base: Path) -> None:
    from diagrams import Cluster, Diagram, Edge
    from diagrams.generic.network import Firewall, Router, Switch
    from diagrams.generic.device import Mobile, Tablet
    from diagrams.onprem.client import Client

    cats = snapshot.get("categories", {})
    devices = cats.get("devices") or []
    clients = cats.get("clients") or []
    topology = cats.get("topology") or {}
    sysinfo = cats.get("system_info") or {}

    controller = sysinfo.get("hostname") or sysinfo.get("name") or "UDM Pro"

    # Identify gateway
    gateway_dev = None
    aps = []
    switches = []
    for d in devices:
        if not isinstance(d, dict):
            continue
        t = (d.get("type") or "").lower()
        model = (d.get("model") or "").lower()
        if t in ("ugw", "udm") or "udm" in model or "ugw" in model:
            gateway_dev = d
        elif t == "uap" or "u7" in model or model.startswith("uap"):
            aps.append(d)
        elif t == "usw" or model.startswith("us") or "switch" in model:
            switches.append(d)

    # Identified clients = those with non-default name
    identified = [c for c in clients if isinstance(c, dict) and (c.get("name") or c.get("note"))]
    transient_count = max(0, len(clients) - len(identified))

    for fmt in ("svg", "png"):
        with Diagram(
            "Physical Topology",
            filename=str(out_base.with_suffix("")),
            outformat=fmt,
            show=False,
            direction="TB",
            graph_attr={"fontsize": "16", "bgcolor": "white", "pad": "0.5", "splines": "ortho"},
        ):
            internet = Router("Internet (WAN)")
            gw_label = controller
            if gateway_dev:
                gw_label += f"\n{gateway_dev.get('model','')}"
                gw_label += f"\n{gateway_dev.get('ip','')}"
            gateway = Firewall(gw_label)
            internet >> gateway

            # Switches first (downlinks from gateway)
            switch_nodes = {}
            for sw in switches:
                slabel = f"{sw.get('name','switch')}\n{sw.get('model','')}"
                node = Switch(slabel)
                gateway >> Edge(label="LAN") >> node
                switch_nodes[sw.get("mac") or sw.get("_id")] = node

            # APs
            ap_nodes = {}
            for ap in aps:
                alabel = f"{ap.get('name','AP')}\n{ap.get('model','')}\n{ap.get('ip','')}"
                node = Switch(alabel)  # Switch icon used as AP placeholder
                gateway >> Edge(label="wireless") >> node
                ap_nodes[ap.get("mac") or ap.get("_id")] = node

            # Identified clients grouped by where they connect
            wired_by_switch = {}
            wireless_by_ap = {}
            for c in identified:
                if c.get("is_wired"):
                    sw_mac = c.get("sw_mac") or c.get("uplink_mac")
                    wired_by_switch.setdefault(sw_mac, []).append(c)
                else:
                    ap_mac = c.get("ap_mac") or c.get("uplink_mac")
                    wireless_by_ap.setdefault(ap_mac, []).append(c)

            for sw_mac, clist in wired_by_switch.items():
                parent = switch_nodes.get(sw_mac) or gateway
                with Cluster(f"Wired ({len(clist)})"):
                    for c in clist[:15]:
                        clabel = f"{c.get('name') or c.get('hostname','?')}\n{c.get('ip','')}"
                        n = Client(clabel)
                        parent >> Edge(style="solid") >> n

            for ap_mac, clist in wireless_by_ap.items():
                parent = ap_nodes.get(ap_mac) or gateway
                with Cluster(f"Wireless ({len(clist)})"):
                    for c in clist[:15]:
                        clabel = f"{c.get('name') or c.get('hostname','?')}\n{c.get('ip','')}"
                        n = Mobile(clabel)
                        parent >> Edge(style="dashed") >> n

            if transient_count:
                with Cluster(f"Transient and unknown ({transient_count})"):
                    Tablet("(see inventory.md)")


def main() -> int:
    if len(sys.argv) != 3:
        die("usage: homenet-render-diagrams.py <snapshot.json> <output-dir>")

    snapshot_path = Path(sys.argv[1]).expanduser().resolve()
    out_dir = Path(sys.argv[2]).expanduser().resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    try:
        import diagrams  # noqa: F401
    except ImportError:
        die(
            "Python 'diagrams' package not installed.\n"
            "  pip3 install diagrams\n"
            "  brew install graphviz"
        )

    snapshot = load_snapshot(snapshot_path)

    # diagrams writes files in cwd. chdir to the output dir so filenames resolve.
    import os
    cwd = os.getcwd()
    try:
        os.chdir(out_dir)
        render_logical(snapshot, out_dir / "logical-network")
        render_physical(snapshot, out_dir / "physical-topology")
    finally:
        os.chdir(cwd)

    # Report
    expected = [
        "logical-network.svg", "logical-network.png",
        "physical-topology.svg", "physical-topology.png",
    ]
    print("Rendered diagrams:")
    for name in expected:
        p = out_dir / name
        if p.exists():
            print(f"  OK   {p} ({p.stat().st_size} bytes)")
        else:
            print(f"  MISS {p}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
