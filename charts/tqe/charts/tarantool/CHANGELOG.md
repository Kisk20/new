# Changelog

## Unreleased
## [0.4.3] - 2025-04-16

* add env vars and secrets vars from values

## [0.4.2] - 2025-04-07

* Small fix in deployment.yaml

## [0.4.1] - 2025-04-04

* Added mechanism to remove Job, Bootstrap Job
* Reworked init-containers
* Added TCM initial-settings

## [0.4.0] - 2025-03-26

* Added matchLables and templateLabels support
* Fix for bootstrap job to wait until cluster is ready

## [0.3.0] - 2025-03-10

* Added affinity, nodeSelector and tolerations support
* Added switch to disable storage's PVCs if necessary
* Added parameters for liveness probes
* Added supervised failover support
* Added PVC RetentionPolicy support
* Added named ports support
* Added settings for logging
* Added automated secrets creation

## [0.2.2] - 2024-11-28

* Fixed `.helmignore` to ignore `.gitlab-ci.yml`
* Fixed default CPU values for routers and storages

## [0.2.1] - 2024-11-26

Restructured storage replicasets: since this release, Tarantool helm chart
uses separate statefulset for separate replicasets.

## [0.2.0] - 2024-11-06

Added timeout for TT CLI to fix autobootstrap

## [0.1.0] - 2024-09-09

Added helm chart to start Tarantool in the following configuration:
* routers
* storages
* etcd
* TCM (optional)
