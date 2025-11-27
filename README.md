# Clash Docker Stack

基于 Docker Compose 的三容器方案，用于运行 Clash、本地 Subconverter 以及定时同步订阅配置文件。项目开箱即用，自带 `clash` 二进制、地理库 `Country.mmdb` 与示例自动化脚本，可在本地或 NAS/云主机上部署。

## 组件说明

| 服务 | 说明 |
| ---- | ---- |
| `clash` | 自定义镜像，基于 `Dockerfile` 构建，启动 `clash -d /etc/clash` 并挂载宿主的 `config.yaml`。 |
| `subconverter` | 上游开源镜像 `tindy2013/subconverter:0.9.0`，提供订阅转换 API，供脚本调用。 |
| `cron` | 基于 `cron/Dockerfile` 构建的 Alpine 镜像，安装 `curl/bash/python3` 等依赖，通过 `crond` 周期性调用 `update_clash.sh`。 |

## 目录结构

```
clash-docker/
├─ Dockerfile              # 构建 clash 服务所需镜像
├─ docker-compose.yml      # 三个容器的编排定义
├─ config.yaml             # Clash 主配置，需提前准备
├─ Country.mmdb            # 地理 IP 数据库
└─ cron/
   ├─ Dockerfile           # cron 服务镜像定义
   ├─ crontab.config       # 定时任务入口（默认每 4 小时执行）
   └─ update_clash.sh      # 自动下载 & 修改 & 热加载配置的脚本
```

## 快速开始

1. 准备 Clash 配置：根据自身需求编辑根目录的 `config.yaml`。
2. 设置订阅变量：在 `cron/update_clash.sh` 中填入 `SUB_URL` 等自定义项。
3. 构建镜像：`docker compose build`.
4. 启动服务：`docker compose up -d`.
5. 查看日志：`docker compose logs -f clash`、`... cron` 以确认运行状态。

## 自动更新流程

1. `cron` 容器通过 `/etc/crontabs/root` 中的 `crontab.config` 设定周期（默认 `0 */4 * * *`）。
2. 任务触发后执行 `update_clash.sh`：  
   - 使用 `subconverter` API 将订阅转换为 Clash 配置；  
   - 进行关键词过滤与字段替换；  
   - 覆盖宿主共享的 `/etc/clash/config.yaml`；  
   - 调用 `http://clash:9090/configs` 热重载 Clash。
3. 日志输出到 `cron` 容器内 `/var/log/clash_update.log`，可用于排查。

## 注意事项

1.所有容器时区均为UTC。  
2.如果不需要基于订阅链接自动更新配置文件，可以在docker-compose.yml中仅保留clash容器。  
3.crontab.config必须在宿主机设置以下权限，否则不生效。   
```
chown root:root cron/crontab.config
chmod 600 cron/crontab.config
```
4.可以在update_clash.sh中自定义修改config.yaml中的配置。
5.首次使用，保证config.yaml中external-controller绑定地址为0.0.0.0:9090。

## 常见问题

- **订阅转换失败**：确认 `SUB_URL` 可访问、`subconverter` 容器处于 `running` 状态，必要时查看其日志。
- **定时任务未触发**：检查 `cron` 容器是否启动、`crontab.config` 权限是否按上述要求设置。
- **Clash 未刷新配置**：确认Clash API端口9090是否绑定在0.0.0.0。
