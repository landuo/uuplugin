# UU 主机加速器 Docker 旁路由

基于 [blindlight/uuplugin](https://github.com/blindlight86/uuplugin) 的轻量 OpenWrt 容器，修复旧镜像内置的 UU 安装地址，并在启动时配置局域网转发。用户只需填写局域网网口、网段、路由器 IP、UU IP 和 DNS，Compose 会创建 macvlan 网络并启动容器。

**支持范围：**目前镜像仅构建 `linux/amd64`。UU 官方插件在容器首次启动时从网易服务器下载；仓库和镜像均不打包 UU 插件、账号或设备绑定数据。当前配置需要 Docker 宿主机支持 macvlan 和特权容器。

## 快速启动

```bash
git clone https://github.com/landuo/uuplugin.git
cd uuplugin
cp .env.example .env
```

编辑 `.env`，将示例值改成自己的网络参数：

| 参数 | 用途 | 示例 |
| --- | --- | --- |
| `PARENT_IFACE` | NAS 上连接局域网的物理网口 | `eth0` |
| `LAN_SUBNET` | 局域网网段 | `192.168.1.0/24` |
| `ROUTER_IP` | 主路由地址 | `192.168.1.1` |
| `UU_IP` | 分给 UU 容器的固定地址 | `192.168.1.251` |
| `DNS_IP` | 容器使用的上游 DNS，通常为主路由 | `192.168.1.1` |
| `LAN_NETMASK` | 与网段对应的子网掩码，默认 `/24` | `255.255.255.0` |

`UU_IP` 必须位于 `LAN_SUBNET` 内，且不能被其他设备使用；建议从主路由 DHCP 地址池排除。`PARENT_IFACE` 可通过宿主机的 `ip -br addr` 或 `ip route` 确认。

```bash
docker compose config
docker compose up -d
docker compose ps
```

`docker compose up -d` 会拉取 `ghcr.io/landuo/uuplugin:latest` 并创建网络。第一次启动需要访问网易的安装服务器，等待容器健康状态变为 `healthy`：

```bash
docker compose logs --tail=100 uuplugin
docker compose ps
```

若局域网设备无法访问 UU IP，检查物理网口是否支持多个 MAC 地址；某些单网口设备需要在宿主机启用混杂模式：

```bash
sudo ip link set PARENT_IFACE promisc on
```

将 `PARENT_IFACE` 换成实际网口名。宿主机与同一物理网口上的 macvlan 容器默认可能无法直接通信，因此应从另一台局域网设备验证。使用 fnOS、OVS、虚拟机或已有 macvlan 网络时，先确认现有网络拓扑；这份 Compose 面向新建 macvlan 网络的部署。

## 绑定与加速

1. 首次绑定时，临时将手机 Wi-Fi 的网关和 DNS 改为 `UU_IP`，在 UU 主机加速 App 中绑定路由器插件，完成后把手机网络设置恢复。
2. 将 Xbox、PlayStation 或 Switch 的网关和 DNS 设置为 `UU_IP`，在 App 中选择设备并开启加速。
3. 在游戏主机上测试网络连接、NAT 类型，并实际进入游戏验证。

上述绑定方式来自[上游 Docker 项目说明](https://github.com/blindlight86/uuplugin)。本镜像不提供 Web 管理页面。

## 检查运行状态

```bash
docker exec uuplugin ps w | grep -i '[u]uplugin'
docker exec uuplugin sh -c 'cat /proc/sys/net/ipv4/ip_forward; iptables -S FORWARD; iptables -t nat -S POSTROUTING'
```

应有 UU 监控进程、`/tmp/uu/uuplugin`、`ip_forward=1`、`br-lan` 转发和 `MASQUERADE` 规则。如果安装失败，先查看 `docker compose logs uuplugin`；旧版镜像的安装地址已经失效，本镜像使用网易 OpenWrt v2 安装脚本。启动脚本会在每次容器启动时重新执行安装器，以初始化新容器的 rootfs，并在持久化卷中保留绑定状态。

## 数据与安全

Compose 将绑定状态保存在 Docker 卷 `uuplugin_uu_state` 和 `uuplugin_uu_data`。升级或重建容器时保留这两个卷；执行 `docker compose down -v` 会删除它们，可能需要重新绑定。

以下内容不得提交到 GitHub，也不得放进镜像构建上下文：

- `uu_state/`、`uu_data/`、`data/`；
- `.sn`、`.uuplugin_uuid`、`.uu.db`、`uu.conf`、激活状态、日志及 UU 下载包；
- 真实的 `.env`、账号令牌、NAS 私有配置和备份。

仓库通过 `.gitignore` 排除常见状态文件，通过只允许 Dockerfile、脚本、许可和归属声明的 `.dockerignore` 限制构建上下文。发布工作流也会拒绝已跟踪的私有运行文件。不要对已经绑定账号的运行中容器执行 `docker commit` 后公开镜像。

容器目前使用 `privileged: true`，因为其 OpenWrt 环境要管理网桥、TUN 和 iptables。只在可信的 Docker 宿主机上运行；未验证更小权限集前，不宣称可安全去掉特权模式。

## 构建与许可

本仓库的新增脚本采用 MIT 许可，见 [LICENSE](LICENSE)；上游项目及网易 UU 插件的归属见 [NOTICE.md](NOTICE.md)。上游镜像已固定到已核对的 digest，避免 `latest` 静默变化。GitHub Actions 在推送到 `main` 后构建 `linux/amd64` 镜像并发布到 GHCR。首次发布后需确认 GHCR 包的可见性为 **Public**，匿名用户才能直接拉取。

本项目是社区实现，与网易 UU 无官方关联。网易提供的安装脚本会在容器启动时执行；使用者应自行确认其服务条款。
