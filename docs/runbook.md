# Runbook — 日常操作与故障处理

面向值班工程师，目标是「照着做就能处理」，而不是描述原理。

## 常用操作

### 查看应用状态
```bash
kubectl -n showcase-dev get pods
kubectl -n showcase-dev logs -l app=showcase-api --tail=100 -f
kubectl -n showcase-dev describe pod <pod-name>
```

### 手动扩缩容
```bash
kubectl -n showcase-dev scale deployment/showcase-api --replicas=5
```

### 回滚到上一版本
```bash
kubectl -n showcase-prod rollout undo deployment/prod-showcase-api
kubectl -n showcase-prod rollout status deployment/prod-showcase-api --timeout=120s
```

### 查看告警
- Grafana → Showcase folder → `Showcase API — Golden Signals`
- Prometheus → Alerts 页面（本地 `make prometheus` 后访问 `http://localhost:9090/alerts`）

---

## 故障处理卡片

### HighErrorRate（5xx 错误率 > 5%）
1. 确认范围：Grafana 看是全部 endpoint 还是个别。
2. 查日志：`kubectl logs -l app=showcase-api --since=10m | grep 503`，本应用故障注入用 `detail=injected upstream failure` 标识。
3. 若由某次发布引起 → 回滚（见上）。
4. 若持续 → 检查上游依赖 / 资源限额（`kubectl top pod`）。

### TargetDown（目标不可达）
1. `kubectl get endpoints showcase-api` 看是否有后端 Pod。
2. 检查 readinessProbe 是否失败：`kubectl describe pod`。
3. 检查 NetworkPolicy 是否误拦截 monitoring 命名空间抓取。

### PodCrashLooping
1. `kubectl describe pod` 看 Last State / Exit Code。
2. `kubectl logs <pod> --previous` 看崩溃前日志。
3. 常见原因：OOMKilled（调高 memory limit）、配置缺失（检查 ConfigMap/Secret）。

---

## 演练：用日志定位一次故障

本应用内置故障注入，可安全演练「告警 → 定位 → 恢复」全流程：

```bash
# 1. 制造错误（docker-compose 方式）
for i in $(seq 1 50); do curl -s "http://localhost:8000/api/items?fail=1" >/dev/null; done

# 2. 在 Prometheus (http://localhost:9090) 执行查询，观察错误率上升：
#    sum(rate(http_requests_total{http_status=~"5.."}[1m])) / sum(rate(http_requests_total[1m]))

# 3. 等待 1 分钟，HighErrorRate 告警变为 firing

# 4. 定位：错误集中在 /api/items，日志/指标指向 fail 参数注入

# 5. 恢复：停止注入，错误率回落，告警自动 resolve
```

> 这次演练对应的完整复盘见 [`postmortem-2026-11-01.md`](postmortem-2026-11-01.md)。它展示了如何用证据链（指标 → 日志 → 时间线）还原一次故障。
