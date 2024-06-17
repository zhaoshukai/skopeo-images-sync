# Synchronize images
使用 skopeo 工具同步镜像到其它仓库。

## 配置 skopeo 工具
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
    - my-registry.local.lan/repo/repo/httpd:latest
    - my-registry.local.lan/repo/grafana/grafana:9.5.3

### 使用 skopeo sync 同步镜像
  - 运行命令
    ```
    $ skopeo sync --src yaml --dest docker sync.yml my-registry.local.lan/repo/
    ```
  - 目标仓库内容（目标仓库路径被压缩）：
    ```
    my-registry.local.lan/repo/repo/httpd:latest
    my-registry.local.lan/repo/grafana:9.5.3
    ```
