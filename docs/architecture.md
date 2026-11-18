# 架构设计说明

## 分层模型

```
┌─────────────────────────────────────────────────┐
│  交付层   GitHub Actions (CI/CD)                 │
│  lint → test → build → push → deploy → verify    │
└──────────────────┬──────────────────────────────┘
                   │ 镜像 / Manifests
┌──────────────────▼──────────────────────────────┐
│  编排层   Kubernetes                             │
│  Deployment · Service · Ingress · HPA · NetPol   │
└──────────────────┬──────────────────────────────┘
                   │ 声明式资源
┌──────────────────▼──────────────────────────────┐
│  基建层   Terraform (in-cluster)                 │
│  namespaces · ingress-nginx · kube-prom-stack    │
└──────────────────┬──────────────────────────────┘
                   │ kubeconfig
┌──────────────────▼──────────────────────────────┐
│  集群层   kind (本地) / EKS-ACK-GKE (生产)        │
└─────────────────────────────────────────────────┘
```

**核心原则：每层只依赖下一层的接口，不跨层操作。** 这样替换任意一层（如 kind → EKS）时，上层代码无需改动。

## 为什么集群层与基建层分离

Terraform 的 `kubernetes`/`helm` provider 在 `init` 阶段就需要一个可用的 kubeconfig。如果让 Terraform 同时创建集群，会形成 **先有鸡还是先有蛋** 的循环依赖。因此：

- 集群由 `kind`（本地）或云厂商的专门 module 创建，它输出 kubeconfig
- Terraform 根模块消费这个 kubeconfig，只管理集群**内部**的声明式资源
- 这正好对应真实组织里的分工：平台团队管集群，应用团队管工作负载

## 可观测性数据流

```
Pod /metrics  ──scrape(15s)──▶  Prometheus  ──eval rules──▶  Alertmanager
                                     │
                                     └──query──▶ Grafana (Golden Signals)
```

采用 **RED 方法**（Rate / Errors / Duration）+ USE 补充，Dashboard 中的四个面板分别对应请求速率、错误率、延迟分位数、并发数。

告警分级：`severity=warning` 走默认接收器，`critical` 走值班通道，并用 `inhibit_rules` 避免告警风暴。

## 从本地到生产的映射

| 关注点 | 本地（kind） | 生产 | 演进影响 |
|--------|-------------|------|---------|
| 集群 | kind | EKS/ACK | 仅替换 kubeconfig 来源 |
| 节点伸缩 | 固定 2 worker | 托管节点组 + CA | 无（应用无感） |
| 存储 | emptyDir | CSI PVC | 有状态服务需改 volume |
| 网络 | NodePort | Ingress + 云 LB | 改 Ingress class |
| 部署策略 | RollingUpdate | ArgoCD 蓝绿/金丝雀 | 换 CD 工具，清单复用 |
| 日志 | stdout | Loki/EFK | 加 DaemonSet 采集 |

## 权衡与取舍

- **Kustomize vs Helm**：都保留。Kustomize 无模板、纯 YAML patch，适合环境差异小的场景；Helm 有模板和 values，适合做成可分发的产品。面试中能讲清取舍比只会一种更有价值。
- **告警规则写在 ConfigMap 还是 Helm values**：生产用 Helm values（`kube-prometheus-stack` 的 `additionalPrometheusRulesMap`），更可维护；本仓库的 `alerts.yml` 用于 docker-compose 演示和教学。
- **不用 service mesh**：本规模引入 Istio 属于过度设计；用 NetworkPolicy + Ingress 已覆盖基本治理需求。
