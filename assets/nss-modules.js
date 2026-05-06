// @namespace: OpenWRT-CI
// NSS 内核模块 (固定开启)

const NSS_MODULES = [
  'kmod-qca-nss-drv','kmod-qca-nss-ecm','kmod-qca-nss-dp',
  'kmod-nss-ifb','kmod-qca-nss-drv-bridge-mgr','kmod-qca-nss-drv-pppoe',
  'kmod-qca-nss-drv-vlan-mgr','kmod-qca-nss-drv-gre','kmod-qca-nss-drv-l2tpv2',
  'kmod-qca-nss-drv-vxlanmgr','kmod-qca-nss-drv-mirror','kmod-qca-nss-drv-tunipip6',
  'kmod-qca-nss-drv-wifi-meshmgr',
];

// ═══════════════════════════════════════
//  状态
// ═══════════════════════════════════════
const STORAGE_KEY = 'openwrt-ci-state';

let state = {
  sourceBranch: 'main-nss',
  target: 'qualcommax',
  subtarget: 'ipq807x',
  firewall: 'iptables',
  template: 'base',
  devices: new Set(),
  plugins: new Set(),
  customOpts: [],
};

