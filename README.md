# Clash Docker

该项目可以实现在Linux运行Clash，并自动定时从订阅链接更新配置文件，不必再担心固定配置失效的问题，可在快速在云主机或本地服务器上部署。

## 组件说明

| 服务             | 说明                                         |
| -------------- | ------------------------------------------ |
| `clash`        | 基于`Ubuntu:24.04`镜像构建，运行clash基础服务。          |
| `subconverter` | 基于`tindy2013/subconverter`镜像，提供订阅转换API的服务。 |
| `cron`         | 基于`Alpine`镜像构建，用于触发定时更新。                   |

## 目录结构

```
clash-docker/
├─ Dockerfile              # 构建clash服务所需镜像
├─ docker-compose.yml      # 三个容器的编排定义
├─ config.yaml             # Clash主配置
├─ Country.mmdb            # 地理IP数据库
├─ clash                   # clash-linux-amd64的二进制文件，版本为1.18.0
└─ cron/
   ├─ Dockerfile           # cron服务镜像定义
   ├─ crontab.config       # 定时任务入口（默认每 4 小时执行）
   └─ update_clash.sh      # 自动更新脚本
```

## 快速开始

1. 安装`docker`和`docker-compose(Version > 2)`
2. 准备Clash配置（可选）：可保持默认不用修改，之后基于订阅链接生成并更新。
3. 设置订阅链接：在 `cron/update_clash.sh` 中填入 `SUB_URL` 。
4. 构建镜像：`docker-compose --build`
5. 启动服务：`docker-compose up -d`
6. 查看日志：`docker-compose logs -f` 
7. 手动更新一次配置（可选）：手动运行更新一次订阅，生成有效可用的配置文件。

## 自动更新流程

1. `cron` 容器通过 `/etc/crontabs/root` 中的 `crontab.config` 设定周期（默认 `0 */4 * * *`）。
2. 任务触发后执行 `update_clash.sh`：  
   - 使用 `subconverter` API 将订阅转换为 Clash 配置；  
   - 进行关键词过滤与字段替换；  
   - 覆盖宿主共享的 `/etc/clash/config.yaml`；  
   - 调用 `http://clash:9090/configs` 热重载 Clash。
3. 日志输出到 `cron` 容器内 `/var/log/clash_update.log`，可用于排查。

## 注意事项

1. 所有容器时区均为UTC。

2. `crontab.config`必须在宿主机设置以下权限，否则不生效。   
   
   ```
   chown root:root cron/crontab.config
   chmod 600 cron/crontab.config
   ```

3. 可以在`update_clash.sh`中自定义修改`config.yaml`中的配置。

4. 首次使用，保证`config.yaml`中`external-controller`绑定地址为`0.0.0.0:9090`，否则将无法重新加载clash配置。

5. 如果不需要基于订阅链接自动更新配置文件，可以在`docker-compose.yml`中仅保留clash容器。
