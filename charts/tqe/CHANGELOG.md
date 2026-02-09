## [2.5.2](https://gitlab.corp.mail.ru/tarantool/k8s/helm-chart-tqe/compare/2.5.1...2.5.2) (2025-06-19)


### Bug Fixes

* Update chart to TQE 2.5.2 ([68b71f7](https://gitlab.corp.mail.ru/tarantool/k8s/helm-chart-tqe/commit/68b71f7585e1ff6ae53560df76d2d382412df52f))
* Update default TT image for autobootstrap to 2.10.0 ([e4c77ee](https://gitlab.corp.mail.ru/tarantool/k8s/helm-chart-tqe/commit/e4c77ee4df8851eab320141a5f49e948c82efc8b))

## [2.5.1](https://gitlab.corp.mail.ru/tarantool/k8s/helm-chart-tqe/compare/2.5.0...2.5.1) (2025-06-19)


### Bug Fixes

* TNTP-3280: Update TQE to 2.5.1 ([9aa1322](https://gitlab.corp.mail.ru/tarantool/k8s/helm-chart-tqe/commit/9aa13223679e977608e37be63a080a19fc9fdbe9))

# [2.5.0](https://gitlab.corp.mail.ru/tarantool/k8s/helm-chart-tqe/compare/2.4.0...2.5.0) (2025-06-18)


### Bug Fixes

* [TNTP-964] _helpers and gRPC refactoring ([ed9e465](https://gitlab.corp.mail.ru/tarantool/k8s/helm-chart-tqe/commit/ed9e4650deef65f8008594b3fd43acd079c57bd1))
* TNTP-2212: Changed deployment to statefulset for GRPC instances ([5d8f449](https://gitlab.corp.mail.ru/tarantool/k8s/helm-chart-tqe/-/commit/5d8f449cbd88f3eccfd9e58f79581675496348b2))
* TNTP-2448: Data was not being saved to PVC ([183954c](https://gitlab.corp.mail.ru/tarantool/k8s/helm-chart-tqe/-/commit/183954cab527d169fe677118d63c13027de31c8b))
* TNTP-2500: Added `autoBootstrap` section to values.yml ([b6f0882](https://gitlab.corp.mail.ru/tarantool/k8s/helm-chart-tqe/-/commit/b6f0882edde67733d4ede059046fba6741debb02))
* TNTP-2999: Updated .helmignore ([24be5e9](https://gitlab.corp.mail.ru/tarantool/k8s/helm-chart-tqe/commit/24be5e930509b4f960ee29a7f817fb350eab7b19))
* TNTP-3056: enabled `reflection_api` and bumped TQE to 2.5.0 ([1c31928](https://gitlab.corp.mail.ru/tarantool/k8s/helm-chart-tqe/commit/1c319284e9e3e50a58501b96fce68fce5fd1a129))


### Features

* TNTP-863: Added custom env variable definition for GRPC instances (e.g. GOMAXPROCS) ([297ef3f](https://gitlab.corp.mail.ru/tarantool/k8s/helm-chart-tqe/-/commit/297ef3f1ec899be68a408028abc27da91cc361e6))
* TNTP-2885: added multishard connection for gRPC consumer ([81fa891](https://gitlab.corp.mail.ru/tarantool/k8s/helm-chart-tqe/commit/81fa8915f0b03d535ab3aa9b631a2b3f523e310a))
* TNTP-2982: Added configuration file for semantic-release ([92e3606](https://gitlab.corp.mail.ru/tarantool/k8s/helm-chart-tqe/commit/92e36064a167f54c873eeaa952b36512d470682f))
* TNTP-3212: Add additional GRPC-endpoints options support ([5579a0f](https://gitlab.corp.mail.ru/tarantool/k8s/helm-chart-tqe/commit/5579a0ff94b2d125bc7e2d1e5b2ccb1da4a036ed))

## [0.4.2] - 2025-04-07

* Small fixes with Submodule Tarantool

## [0.4.1] - 2025-04-04

* Small beauty fix with Submodule Tarantool

## [0.4.0] - 2025-03-26

* Fixed gRPC-configs

## [0.3.0] - 2025-03-10

* Add cpuLimits and memoryLimits for gRPC-endpoints

## [0.1.3] - 2024-12-16 

* Added affinity, nodeSelector and tolerations
* Added resources (requests, limits)
* Added custom labels (spec.selector.matchLabels and spec.template.metadata.labels)

## [0.1.2] - 2024-11-28

Fixed `.helmignore`, so `.gitlab-ci.yml` is no more in release archive.

## [0.1.1] - 2024-11-19

* Bumped Tarantool helm chart (added separate statefulsets for each TT replicaset).
* Connect gRPC consumer directly to the storage, not to the service.

## [0.1.0] - 2024-11-14

Added helm chart to start gRPC instances over [Tarantool helm chart][1], based on
[Tarantool Queue Enterprise][2].

[1](https://gitlab.corp.mail.ru/tarantool/k8s/helm-chart-tarantool)
[2](https://www.tarantool.io/ru/queue-enterprise/doc/latest/)
