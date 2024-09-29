# Synchronize images
使用 skopeo 工具同步镜像到其它仓库。

## 说明
### 主要文件
- [sync.yaml](images/images.yaml)
  `skopeo sync` 命令格式的镜像清单文件，同时也用于 **skopeo copy** 命令。
- [skopeo-copy.sh](.github/tools/skopeo-copy.sh)
  一个用来解析 **[sync.yaml](images/images.yaml)** 并转换为 `skopeo copy` 格式的小脚本。
- [Actions - Main](.github/workflows/main.yaml)
  通过 `skopeo copy` 命令同步到仓库名称 **不支持斜线** 的一些公有云仓库，如：**ccr.ccs.tencentyun.com**、**registry.aliyuncs.com**。
- [Actions - Harbor](.github/workflows/harbor.yaml)
  通过 `skopeo sync` 命令同步到仓库名称 **支持斜线** `my-registry.local.lan`/`repo`/`grafana/grafana`:`9.5.3` 的自建仓库，如 **Harbar**。

### Actions 环境变量
- 自建 Harbor 镜像仓库（仓库名支持斜线）
  | Actions变量  | 引用变量           | 变量类型   | 备注             |
  |--------------|-------------------|-----------|------------------|
  | REGISTRY     | HARBOR_REGISTRY   | variables | Harbor 服务地址   |
  | REPOSITORY   | HARBOR_REPOSITORY | variables | Harbor 仓库项目名 |
  | USERNAME     | HARBOR_USERNAME   | secrets   | Harbor 用户名     |
  | PASSWORD     | HARBOR_PASSWORD   | secrets   | Harbor 用户密码   |

- 公有云 镜像仓库（仓库名不支持斜线）
  | Actions变量  | 引用变量              | 变量类型   | 备注             |
  |--------------|----------------------|-----------|------------------|
  | REGISTRY     | PUBLIC_CR_REGISTRY   | variables | 仓库服务地址      |
  | REPOSITORY   | PUBLIC_CR_REPOSITORY | variables | 仓库命名空间名称  |
  | USERNAME     | PUBLIC_CR_USERNAME   | secrets   | 仓库登陆名        |
  | PASSWORD     | PUBLIC_CR_PASSWORD   | secrets   | 仓库登陆密码      |

### 其它
- `skopeo copy` 命令会将结果写入 [.sync](images/images.yaml.sync) 文件，如需要重新同步可删除相关文件或特定镜像的tag。
- `skopeo list-tags REPOSITORY-NAME` 命令可以获取特定镜像的tag列表，如：
  > skopeo list-tags docker://docker.io/fedora

## skopeo 命令示例
### 配置 镜像清单 文件
- 镜像清单文件示例：
  ```
  docker.io:
    tls-verify: false
    images:
      httpd:
        - latest
      grafana/grafana:
        - latest
        - 9.5.3
  quay.io:
    tls-verify: false
    images: 
      coreos/etcd:
        - latest
  192.168.10.80:5000:
    images:
      busybox: [stable]
      redis:
        - latest
        - 7.0.5
    credentials:
      username: registryuser
      password: registryuserpassword
    tls-verify: true
    cert-dir: /etc/containers/certs.d/192.168.10.80:5000
  ```

### 使用 skopeo copy 复制镜像
- 运行命令
  ```
  $ skopeo copy docker://docker.io/httpd:latest docker://my-registry.local.lan/repo/httpd:latest
  $ skopeo copy docker://docker.io/grafana/grafana:9.5.3 docker://my-registry.local.lan/repo/grafana/grafana:9.5.3
  ```
- 目标仓库内容（目标仓库路径为指定）：
  ```
  my-registry.local.lan/repo/httpd:latest
  my-registry.local.lan/repo/grafana/grafana:9.5.3
  ```

### 使用 skopeo sync 同步镜像
- 运行命令
  ```
  $ skopeo sync --src yaml --dest docker sync.yml my-registry.local.lan/repo/
  ```
- 目标仓库内容（目标仓库路径被压缩）：
  ```
  my-registry.local.lan/repo/httpd:latest
  my-registry.local.lan/repo/grafana:9.5.3
  ```
