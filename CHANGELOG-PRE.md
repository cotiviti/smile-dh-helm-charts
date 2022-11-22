# [1.0.0-pre.7](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.6...v1.0.0-pre.7) (2022-11-22)


### Features

* **smilecdr:** add name override for CrunchyPGO ([110e133](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/110e1336c309adb3602f9103421f0693ca32424d))

# [1.0.0-pre.6](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.5...v1.0.0-pre.6) (2022-11-22)


### Features

* **smilecdr:** add Secrets Store CSI support ([f8f23ba](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/f8f23ba2e3e8b6a87fc80d7cf04a7ae9a221782f))

# [1.0.0-pre.5](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.4...v1.0.0-pre.5) (2022-11-21)


### Features

* **smilecdr:** add support for IRSA (IAM roles) ([509bbe3](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/509bbe389df8e2c908161eb11e9fca7a1df15755))

# [1.0.0-pre.4](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.3...v1.0.0-pre.4) (2022-11-21)


### Features

* **smilecdr:** update Ingress definition logic ([2271d57](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/2271d57ff5bd8aef792ca4310df86eb5913682cf))


### BREAKING CHANGES

* **smilecdr:** Now uses `nginx-ingress` instead of
`aws-lbc-nlb` for specifying Nginx Ingress Controller

# [1.0.0-pre.3](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.2...v1.0.0-pre.3) (2022-11-21)


### Features

* **smilecdr:** add back default tag functionality ([46785e5](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/46785e5ee54087a8ec4df2139f9630827f655d81))
* **smilecdr:** add common labels to all resources ([618ba2e](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/618ba2ed8a96fda736d52dc50519485237dbede8))
* **smilecdr:** normalize resource names ([6ca25bd](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/6ca25bdec998a081aa114eb598702ee6a1819570))
* **smilecdr:** remove extra labels from default values ([d971934](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/d9719344f890baaf8b939f1ef3d641f959775f22))

# [1.0.0-pre.2](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.1...v1.0.0-pre.2) (2022-11-21)


### Features

* **smilecdr:** remove hard coded entries from ConfigMap ([b6a2fb5](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/b6a2fb56ae9324ef08976cf92487ba7b7f1e7f2c))

# 1.0.0-pre.1 (2022-11-21)


### Features

* **repo:** initial Commit ([5f98460](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/5f9846020a2da8d343f55e36e3fa896206717ef8)), closes [#68834381](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/issues/68834381)
* **smilecdr:** add external module files support ([da374c1](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/da374c1a97735a895c27356025650d00da2db4c8))
* **smilecdr:** update application version ([9b203f2](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/9b203f277955fb34831592fe064f19863765b2a1))
