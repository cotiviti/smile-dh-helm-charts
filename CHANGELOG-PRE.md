# [1.0.0-pre.113](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.112...v1.0.0-pre.113) (2024-05-17)


### Bug Fixes

* **kafka:** fix Kafka Admin pod IAM auth ([6a84d77](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/6a84d7738bae6303cf16cb696a6d833c88ff0436))

# [1.0.0-pre.112](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.111...v1.0.0-pre.112) (2024-05-16)


### Features

* **smilecdr:** add cert-manager support ([17e3be5](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/17e3be5b8c3861129f01fde3240b005b71266a0b))

# [1.0.0-pre.111](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.110...v1.0.0-pre.111) (2024-04-11)


### Bug Fixes

* **smilecdr:** auto-set s3 cp recursive option ([045463d](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/045463d66c7c6f3615a0fba2751821c380b714cf))


### BREAKING CHANGES

* **smilecdr:** - If you currently specify a source path without a trailing slash, it will no longer try to recursively copy the files.

# [1.0.0-pre.110](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.109...v1.0.0-pre.110) (2024-03-13)


### Features

* **pgo:** add more configurability to crunchydata PG CRD ([91591e0](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/91591e0c9b268b6dd53ee834782442082fd8dc4e))

# [1.0.0-pre.109](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.108...v1.0.0-pre.109) (2024-03-05)


### Bug Fixes

* **smilecdr:** fix validate topic logic ([c08e65c](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/c08e65cd52e2ba8abc862811436f350af886d343))

# [1.0.0-pre.108](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.107...v1.0.0-pre.108) (2024-03-04)


### Bug Fixes

* **smilecdr:** fix SSCI resource naming ([0e926f5](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/0e926f5bc78052b5800a7233f19d3a2bcce1c40b))

# [1.0.0-pre.107](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.106...v1.0.0-pre.107) (2024-03-03)


### Bug Fixes

* **smilecdr:** update Strimzi schema ([3b65726](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/3b65726f3e2cee286d5a0c4163f275cfcdab2e3d))

# [1.0.0-pre.106](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.105...v1.0.0-pre.106) (2024-02-15)


### Bug Fixes

* **smilecdr:** fix quoting of ingress annotations ([7252dff](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/7252dffe59ddbc9352d7f3ea517903a277dc4ffe))

# [1.0.0-pre.105](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.104...v1.0.0-pre.105) (2024-02-14)


### Features

* **smilecdr:** add configurable logging ([20624ec](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/20624ec51a05dfdb631c1f6363fa0da0df558d5b))

# [1.0.0-pre.104](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.103...v1.0.0-pre.104) (2024-02-13)


### Features

* **smilecdr:** add support for multiple ingresses ([91485d6](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/91485d68a4889c1e0f2d875eda1e9480499af029))

# [1.0.0-pre.103](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.102...v1.0.0-pre.103) (2023-12-08)


### Features

* **smilecdr:** allow custom startup probe timings ([5bfabc5](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/5bfabc51e5a04ac3fe6efd2c1c251583d91689b0))

# [1.0.0-pre.102](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.101...v1.0.0-pre.102) (2023-11-29)


### Bug Fixes

* **smilecdr:** improve handling of issuer.url ([9f0976c](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/9f0976c6ea225ef9fd2f434744b60b8a62650f9f))

# [1.0.0-pre.101](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.100...v1.0.0-pre.101) (2023-11-28)


### Features

* **smilecdr:** add AMQ support ([f724142](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/f72414226307dd8d038f8553de50c47ea1c6aed7))

# [1.0.0-pre.100](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.99...v1.0.0-pre.100) (2023-11-28)


### Features

* **smilecdr:** add Kafka password auth ([bc805fa](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/bc805fadec5228757219524ffd450118f26aedd9))

# [1.0.0-pre.99](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.98...v1.0.0-pre.99) (2023-11-20)


### Bug Fixes

* **smilecdr:** fix route rendering for AppSphere ([903b00e](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/903b00e8788c072e5ec6a247203386297d88e90e))

# [1.0.0-pre.98](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.97...v1.0.0-pre.98) (2023-11-07)


### Bug Fixes

* **smilecdr:** Remove duplicate env vars ([8284743](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/8284743a31da915660aefae8054abbd60adf05fd))

# [1.0.0-pre.97](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.96...v1.0.0-pre.97) (2023-11-03)


### Features

* **smilecdr:** Add instrumentation support ([2583c81](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/2583c816db3f4819b8fb49384d9c41ee0093d001))

# [1.0.0-pre.96](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.95...v1.0.0-pre.96) (2023-09-20)


### Bug Fixes

* **smilecdr:** Fix IAM Jar version in Kafka admin ([f5048f1](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/f5048f13117271d3827b310d1b843d7856c90fd0))

# [1.0.0-pre.95](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.94...v1.0.0-pre.95) (2023-09-19)


### Features

* **smilecdr:** allow custom image repos ([033825a](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/033825a395a7413def09682e7b0ddd70058060bd))

# [1.0.0-pre.94](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.93...v1.0.0-pre.94) (2023-09-07)


### Bug Fixes

* **smilecdr:** multiple init-pull containers ([80ced73](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/80ced73548a612e1580c0204f55cd170301ed595))

# [1.0.0-pre.93](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.92...v1.0.0-pre.93) (2023-08-30)


### Features

* **smilecdr:** add multi-node configuration ([29848e7](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/29848e7df2fa088675e43899fa8cc6cffe521a13))

# [1.0.0-pre.92](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.91...v1.0.0-pre.92) (2023-08-28)


### Features

* **smilecdr:** Update to Smile CDR 2023.08.R01 ([d3b33f1](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/d3b33f1a812c6c5a5a4261175921a91c23b0b971))

# [1.0.0-pre.91](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.90...v1.0.0-pre.91) (2023-08-25)


### Features

* **smilecdr:** add db suffix configuration ([ddf3b63](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/ddf3b63f58798c41c850ee8c19b5a0bcbeb17eb1))

# [1.0.0-pre.90](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.89...v1.0.0-pre.90) (2023-08-25)


### Bug Fixes

* **smilecdr:** add error checking for mapped files ([95b82d0](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/95b82d0a468942fff15b2e6335158c8d0082da72))

# [1.0.0-pre.89](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.88...v1.0.0-pre.89) (2023-08-19)


### Bug Fixes

* **smilecdr:** add config sanity checks ([eea5ae6](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/eea5ae60da1a7fb9ce2ac173d15e365c742f1de2))

# [1.0.0-pre.88](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.87...v1.0.0-pre.88) (2023-08-18)


### Bug Fixes

* **smilecdr:** allow hierarchical config ([f664d5e](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/f664d5e9727d84c4a57e8e928bd547c9368e8571))

# [1.0.0-pre.87](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.86...v1.0.0-pre.87) (2023-07-27)


### Bug Fixes

* **smilecdr:** allow specifying db name ([4d4cd84](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/4d4cd8410922f8edd29896e3754d9ec947c7874e))

# [1.0.0-pre.86](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.85...v1.0.0-pre.86) (2023-06-27)


### Bug Fixes

* **smilecdr:** fix base_url for hybrid provider ([e80367d](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/e80367dd59db59639c0f261edf29796f98751a3d))

# [1.0.0-pre.85](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.84...v1.0.0-pre.85) (2023-06-26)


### Bug Fixes

* **smilecdr:** update default modules ([f83ff90](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/f83ff9089e4c93555efcd25d9545f4b3fe188ab6))

# [1.0.0-pre.84](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.83...v1.0.0-pre.84) (2023-06-26)


### Features

* **smilecdr:** make readiness probe configurable ([e83a98e](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/e83a98e1c411794aaa4001e79f44633e643f1810))

# [1.0.0-pre.83](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.82...v1.0.0-pre.83) (2023-06-20)


### Features

* **smilecdr:** allow disabling of module ingress ([ca3011b](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/ca3011bca4b0f0b2eaa6fa1c21bb24dad3dba550))

# [1.0.0-pre.82](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.81...v1.0.0-pre.82) (2023-06-09)


### Bug Fixes

* **smilecdr:** update transaction module name ([f4472ca](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/f4472cac24ff61a95b6e5a149f7b41d47690b62c))

# [1.0.0-pre.81](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.80...v1.0.0-pre.81) (2023-06-08)


### Features

* **smilecdr:** Update to Smile CDR 2023.05.R02 ([e7362b8](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/e7362b88ebf1fda24779baaff94b2e8dd6f54c4c))

# [1.0.0-pre.80](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.79...v1.0.0-pre.80) (2023-06-06)


### Features

* **smilecdr:** Update to Smile CDR 2023.05.R01 ([99aa74d](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/99aa74d568b35504e3955ce65fdce922428db99f))

# [1.0.0-pre.79](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.78...v1.0.0-pre.79) (2023-06-06)


### Features

* **smilecdr:** Update to Smile CDR 2023.05.R01 ([bf89b79](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/bf89b79b879a6e02f365e50e4829db91822fd566))

# [1.0.0-pre.78](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.77...v1.0.0-pre.78) (2023-06-06)


### Bug Fixes

* **smilecdr:** fix k8s resource labels ([6378fe0](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/6378fe09908748e5bd56aa27a2d73a74cb6db302))

# [1.0.0-pre.77](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.76...v1.0.0-pre.77) (2023-06-06)


### Bug Fixes

* **smilecdr:** fix disableAutoJarCopy option ([03d5163](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/03d5163f3faa971f869167e54af375a64594ed54))

# [1.0.0-pre.76](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.75...v1.0.0-pre.76) (2023-06-06)


### Bug Fixes

* **smilecdr:** update uid for curl images ([a7cb4de](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/a7cb4de7b48d05aba7f806ab6383c03c6b6b3a91))

# [1.0.0-pre.75](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.74...v1.0.0-pre.75) (2023-05-08)


### Bug Fixes

* **common:** remove `chart.shortname` template ([f7a0a8b](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/f7a0a8b124c8ddac280c73664f426b068252a6f2))

# [1.0.0-pre.74](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.73...v1.0.0-pre.74) (2023-05-04)


### Bug Fixes

* **pmp:** add per-component imagePullSecrets logic ([880c74e](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/880c74e229e0799dc0fc255859731f32d3856185))

# [1.0.0-pre.73](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.72...v1.0.0-pre.73) (2023-05-04)


### Features

* **pmp:** add pmp chart ([d52cc0c](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/d52cc0c9822849b9d1aae3ad77884a75b77c8199))

# [1.0.0-pre.72](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.71...v1.0.0-pre.72) (2023-05-02)


### Features

* **pmp:** add pmp-keycloak chart ([10541a4](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/10541a44e473e1a954bbc3c5dcf00b302f7cffa0))

# [1.0.0-pre.71](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.70...v1.0.0-pre.71) (2023-05-01)


### Features

* **pmp:** add pmp-directus chart ([f8c0b1e](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/f8c0b1e0bc9d0d1893fa9cddfac820c83e9e4cc7))

# [1.0.0-pre.70](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.69...v1.0.0-pre.70) (2023-05-01)


### Features

* **common:** add Smile DH common library chart ([46a3e67](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/46a3e673a581963722edc3007b4019146d1a6e7b))

# [1.0.0-pre.69](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.68...v1.0.0-pre.69) (2023-04-05)


### Bug Fixes

* **smilecdr:** fix s3 copy for customerlib ([66ea90a](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/66ea90a2c13efc909bf62354475783670bed77ec))

# [1.0.0-pre.68](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.67...v1.0.0-pre.68) (2023-04-05)


### Bug Fixes

* **smilecdr:** fix s3 copy with readonly rootfs ([f7a6a12](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/f7a6a12ab103e4b8cd82f94e5b393896134c14de))

# [1.0.0-pre.67](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.66...v1.0.0-pre.67) (2023-03-28)


### Bug Fixes

* **smilecdr:** fix kafka configs with IAM auth ([170a14c](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/170a14c3c7cfb288f92edbcc35edca1366404191))

# [1.0.0-pre.66](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.65...v1.0.0-pre.66) (2023-03-27)


### Bug Fixes

* **smilecdr:** fix value for grace period ([54686f7](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/54686f7dfc6680b57748c57b6a94ae73ff31850c))

# [1.0.0-pre.65](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.64...v1.0.0-pre.65) (2023-03-23)


### Bug Fixes

* **smilecdr:** add preStop delay ([2d31c8c](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/2d31c8c6603bdc23240d7851b7fd4a76f9e39db9))

# [1.0.0-pre.64](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.63...v1.0.0-pre.64) (2023-03-22)


### Features

* **smilecdr:** add database properties mode ([bb0b614](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/bb0b614c641c4f18b71a1f2dae7df17e799ea64b))

# [1.0.0-pre.63](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.62...v1.0.0-pre.63) (2023-03-22)


### Bug Fixes

* **smilecdr:** fix licence module settings ([ceab69d](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/ceab69d596e8986b7d74cc0cd821351ecb7c3c9f))

# [1.0.0-pre.62](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.61...v1.0.0-pre.62) (2023-03-22)


### Bug Fixes

* **smilecdr:** use correct labels for Kafka admin ([fce2935](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/fce2935fbd4237240a36ea67ae2d085fcf97d2fa))

# [1.0.0-pre.61](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.60...v1.0.0-pre.61) (2023-03-15)


### Features

* **smilecdr:** add HL7v2 support ([05d5579](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/05d5579c1e61ad01a0edb549f53aad6119da6cf4))

# [1.0.0-pre.60](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.59...v1.0.0-pre.60) (2023-03-08)


### Features

* **smilecdr:** update to latest Smile CDR version ([db1caae](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/db1caaede8a95a4e82f3e62d0ee24f55494b278f))

# [1.0.0-pre.59](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.58...v1.0.0-pre.59) (2023-03-07)


### Features

* **smilecdr:** add Kafka admin pod ([c9f0493](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/c9f0493fb94e98af7d8cb8bd88f0a98b8725b927))
* **smilecdr:** rework Kafka configuration ([d27a00b](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/d27a00b3dd09d42bf62e27d07f957344e978d551))
* **smilecdr:** update consumer properties ([c1978e5](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/c1978e59d8bb088b433917da5edcd78db1b4d2f0))


### BREAKING CHANGES

* **smilecdr:** This affects the default consumer properties
configured in Smile CDR.
* **smilecdr:** Existing Kafka/Strimzi configurations have changed. As
they were previously untested, the required changes may be unpredictable.
Please refer to the docs to configure Kafka.

# [1.0.0-pre.58](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.57...v1.0.0-pre.58) (2023-02-28)


### Bug Fixes

* **smilecdr:** update initContainer configurations ([c974af5](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/c974af5e398db2b840cded466ca68eb6dea38d9f))

# [1.0.0-pre.57](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.56...v1.0.0-pre.57) (2023-02-27)


### Features

* **smilecdr:** improve secrets error handling ([8df9476](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/8df9476ca34df796cbc833b9ff67e9bc8d4c6f35))

# [1.0.0-pre.56](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.55...v1.0.0-pre.56) (2023-02-27)


### Features

* **smilecdr:** improve warnings for chart errors ([b50e54e](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/b50e54ec10caf01a537e96d8d630f227272efcdc))

# [1.0.0-pre.55](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.54...v1.0.0-pre.55) (2023-02-27)


### Features

* **smilecdr:** refactor image pull secrets ([c7d376c](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/c7d376ceca98ae14f275227a4430a3e1e8063306)), closes [#78](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/issues/78)


### BREAKING CHANGES

* **smilecdr:** Deprecation warning - Values files must be updated to use
`image.imagePullSecrets` instead of `image.credentials`.

# [1.0.0-pre.54](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.53...v1.0.0-pre.54) (2023-02-27)


### Bug Fixes

* **smilecdr:** follow redirects for curl ([698d045](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/698d04529675f60788839002c9f1a5c55f3718d9))

# [1.0.0-pre.53](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.52...v1.0.0-pre.53) (2023-02-26)


### Features

* **smilecdr:** add init-sync for customerlib ([099cb57](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/099cb575baee438b383a008dde1b0937dc95a24d))

# [1.0.0-pre.52](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.51...v1.0.0-pre.52) (2023-02-22)


### Features

* **smilecdr:** update to latest Smile CDR version ([d9c0240](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/d9c02408149cafe4c3e8c4dfea3ca30eb6d46041))

# [1.0.0-pre.51](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.50...v1.0.0-pre.51) (2023-02-21)


### Features

* **smilecdr:** improve readiness probe definition ([25273a9](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/25273a9e00fc4d406856edd4c347798e29a50404))

# [1.0.0-pre.50](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.49...v1.0.0-pre.50) (2023-02-21)


### Features

* **smilecdr:** allow extra env vars and volumes ([9d53ec8](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/9d53ec82acb326792837881ba00a05d047da8a4f))

# [1.0.0-pre.49](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.48...v1.0.0-pre.49) (2023-02-21)


### Bug Fixes

* **smilecdr:** use provided tag for initcontainer ([2f68eb6](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/2f68eb6b449fee56a4964b2a204ef5703434f39f))

# [1.0.0-pre.48](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.47...v1.0.0-pre.48) (2023-02-21)


### Features

* **smilecdr:** update k8s secrets mechanism ([0733b5d](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/0733b5d3f3b5f4fcec4be4ce121bb230948e4ce6))

# [1.0.0-pre.47](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.46...v1.0.0-pre.47) (2023-02-21)


### Bug Fixes

* **smilecdr:** correct spelling of license ([25dd99a](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/25dd99a52fb054aa8e6662ff871a3a11f4657203))
* **smilecdr:** use camelCase for `useDefaultModules` ([a0178ac](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/a0178ac5e576cb03f3ce8235fc4ceef738914606))


### BREAKING CHANGES

* **smilecdr:** This change affects the default module configuration.

# [1.0.0-pre.46](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.45...v1.0.0-pre.46) (2023-02-21)


### Bug Fixes

* **smilecdr:** remove short-circuit dependency ([9af24c2](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/9af24c2c3f9bde89f8d26b44735f3ead36a51bdd))

# [1.0.0-pre.45](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.44...v1.0.0-pre.45) (2023-02-09)


### Features

* **smilecdr:** add license support ([3c429d8](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/3c429d822754bceccebfb1783120b876cbcfc8b1))

# [1.0.0-pre.44](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.43...v1.0.0-pre.44) (2023-02-09)


### Bug Fixes

* **smilecdr:** fix paths for initcontainer ([ce17551](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/ce17551b893d14a613ffad8875839ff5086f3f07))

# [1.0.0-pre.43](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.42...v1.0.0-pre.43) (2023-01-30)


### Features

* **smilecdr:** add support for 2023.02 release ([7c583de](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/7c583dec7a70a9ba7f0677df1afcb175a2386f49))

# [1.0.0-pre.42](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.41...v1.0.0-pre.42) (2023-01-30)


### Features

* **smilecdr:** add config locking options ([351d48d](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/351d48d5425ddac08d3e4601843ca281191bf7e2))

# [1.0.0-pre.41](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.40...v1.0.0-pre.41) (2023-01-28)


### Features

* **smilecdr:** add support for Alpine3 base image ([dc7e960](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/dc7e960d3978723238fbd9e91bee565385b2a6f6))

# [1.0.0-pre.40](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.39...v1.0.0-pre.40) (2023-01-28)


### Bug Fixes

* **smilecdr:** fix ingress annotation overrides ([78d254e](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/78d254e3f891a2ae03b9f181a2da9e965017269c))

# [1.0.0-pre.39](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.38...v1.0.0-pre.39) (2023-01-27)


### Bug Fixes

* **smilecdr:** fix key names in env vars ([81defae](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/81defaef33a5fa1f1cadfc4b14f68896f6b7cbff))

# [1.0.0-pre.38](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.37...v1.0.0-pre.38) (2023-01-27)


### Bug Fixes

* **smilecdr:** fix key names in k8s secret ([b84760a](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/b84760aa4df7999c5c151eda437649511c11d88b))

# [1.0.0-pre.37](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.36...v1.0.0-pre.37) (2023-01-26)


### Bug Fixes

* **smilecdr:** change objectAlias naming logic ([ade3f22](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/ade3f22fde28f2d32bbc6699cceb1697b866a33a))

# [1.0.0-pre.36](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.35...v1.0.0-pre.36) (2023-01-11)


### Features

* **smilecdr:** update ingress logic and docs ([affff39](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/affff3956865d817f14988ea420bc61e1b5f38ad))

# [1.0.0-pre.35](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0-pre.34...v1.0.0-pre.35) (2023-01-06)


### Features

* **smilecdr:** copy files from external location ([ea2710f](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/ea2710f406d43b610e7cfa41b2d8e9859f9536d2))

# [1.0.0-pre.34](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.33...v1.0.0-pre.34) (2022-12-22)


### Bug Fixes

* **smilecdr:** fix ConfigMap reference in volume ([5cc81e8](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/5cc81e8c016d7d708ab8d8df39b147665406eec4))

# [1.0.0-pre.33](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.32...v1.0.0-pre.33) (2022-12-22)


### Bug Fixes

* **smilecdr:** force lower case in resource names ([6d1e4aa](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/6d1e4aa1ff27d7541f370859651047065eece060))

# [1.0.0-pre.32](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.31...v1.0.0-pre.32) (2022-12-20)


### Features

* **smilecdr:** change db secret config ([8069b77](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/8069b77d4920ef64154eca12d06c4c788241a831))


### BREAKING CHANGES

* **smilecdr:** Values file needs to be updated if using sscsi for DB
secrets

# [1.0.0-pre.31](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.30...v1.0.0-pre.31) (2022-12-14)


### Features

* **smilecdr:** disable crunchypgo ([a2a4e32](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/a2a4e32f624a5d348d8bf03c5ebcd90dea8dd690))

# [1.0.0-pre.30](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.29...v1.0.0-pre.30) (2022-12-10)


### Features

* **smilecdr:** add argocd feature ([75a4874](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/75a4874bd2da5dede8630babe586143f4f1848b1))

# [1.0.0-pre.29](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.28...v1.0.0-pre.29) (2022-12-10)


### Bug Fixes

* **smilecdr:** fix secret reference keys ([2f6411b](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/2f6411ba5b81fc7139d1335b6b4935405e27556f))

# [1.0.0-pre.28](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.27...v1.0.0-pre.28) (2022-12-06)


### Features

* **smilecdr:** make image secret required ([e068330](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/e068330a9e2b1b890b6008ab5790a5bfa0180c91))

# [1.0.0-pre.28](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.27...v1.0.0-pre.28) (2022-12-05)


### Features

* **smilecdr:** make image secret required ([2c2389b](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/2c2389be7a1533c951c52246de852fe81a7585a0))

# [1.0.0-pre.27](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.26...v1.0.0-pre.27) (2022-12-03)


### Bug Fixes

* **smilecdr:** fix DB_PORT in default modules ([2239f60](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/2239f60ec6d3ea5bc21e77c20431bca03a0dae20))

# [1.0.0-pre.26](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.25...v1.0.0-pre.26) (2022-12-03)


### Bug Fixes

* **smilecdr:** correct the field for image secrets ([2ddeef2](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/2ddeef2a10f176e231130e01c8bdc485875aad73))

# [1.0.0-pre.25](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.24...v1.0.0-pre.25) (2022-12-02)


### Features

* **smilecdr:** support multiple databases ([e28bb13](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/e28bb131b5976e705eed227a6efd3b4cd48c325e))

# [1.0.0-pre.24](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.23...v1.0.0-pre.24) (2022-12-02)


### Bug Fixes

* **smilecdr:** improve modules include logic ([f7850d2](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/f7850d2d47dacd331b902f2cf4c2295e4b385265))

# [1.0.0-pre.23](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.22...v1.0.0-pre.23) (2022-12-02)


### Bug Fixes

* **smilecdr:** allow quoted config entries ([f9d7e1f](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/f9d7e1f9b420926ee0a2d4a7db0960c10f8cf61d))

# [1.0.0-pre.22](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.21...v1.0.0-pre.22) (2022-12-01)


### Bug Fixes

* **smilecdr:** change crunchydata resource names ([654417b](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/654417b7a9dce46f84947d371fa4426b03bf7783))


### Features

* **smilecdr:** improve CrunchyData integration ([4289432](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/428943258417ada4c1dcdd7e9d75bb6cee0139fd))

# [1.0.0-pre.21](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.20...v1.0.0-pre.21) (2022-12-01)


### Features

* **smilecdr:** update JVM tuning params ([cc1f859](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/cc1f8591deb55f9491892995b632a45af44c0d84))

# [1.0.0-pre.20](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.19...v1.0.0-pre.20) (2022-12-01)


### Bug Fixes

* **smilecdr:** remove image reference ([2b47fb5](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/2b47fb56be3397e0cf19899c0d5442fce6419311))

# [1.0.0-pre.19](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.18...v1.0.0-pre.19) (2022-12-01)


### Features

* **smilecdr:** add support for strimzi kafka ([27b8fb4](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/27b8fb4a4d61babec1934024874a4b4a2276b4a2))

# [1.0.0-pre.18](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.17...v1.0.0-pre.18) (2022-12-01)


### Features

* **smilecdr:** add autoscaling support ([6ff0f2f](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/6ff0f2fb33a1df6cd94d22872b5b67e8cf788120))

# [1.0.0-pre.17](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.16...v1.0.0-pre.17) (2022-12-01)


### Features

* **smilecdr:** configure rolling deployments ([daa9c4b](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/daa9c4b43ca9f59b1e26dc7a4a3a1da62d859e1d))

# [1.0.0-pre.16](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.15...v1.0.0-pre.16) (2022-12-01)


### Features

* **smilecdr:** add pod disruption budget ([b8b46e4](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/b8b46e47213a40d29a47020aa3d18c07f4f88558))

# [1.0.0-pre.15](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.14...v1.0.0-pre.15) (2022-12-01)


### Features

* **smilecdr:** add redeploy on config changes ([90e33ad](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/90e33ad5e725957e3c1cd039487e19e88548618d))

# [1.0.0-pre.14](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.13...v1.0.0-pre.14) (2022-11-30)


### Features

* **smilecdr:** add readiness probe ([5a03100](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/5a031005cc9fda8622bc1c2b643d1e3ba156ad6c))
* **smilecdr:** add startup probe ([65014ad](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/65014ad33e4225ece5106fd2d2485f1cd18816d6))

# [1.0.0-pre.13](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.12...v1.0.0-pre.13) (2022-11-25)


### Features

* **smilecdr:** update CDR version and modules ([116e187](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/116e187150326b59d974c2f2624c2a7daa922f12))


### BREAKING CHANGES

* **smilecdr:** - This updates the Smile CDR version

# [1.0.0-pre.12](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.11...v1.0.0-pre.12) (2022-11-25)


### Features

* **smilecdr:** add support for deploying postgres ([0fc81b1](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/0fc81b1d99c95c3e319cab859d52af07774b7429))

# [1.0.0-pre.11](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.10...v1.0.0-pre.11) (2022-11-24)


### Bug Fixes

* **smilecdr:** fix reference to configmap data ([383fdd6](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/383fdd6f18780df4ad3f1b1a7a64fcf10c3ff379))

# [1.0.0-pre.10](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.9...v1.0.0-pre.10) (2022-11-24)


### Features

* **smilecdr:** support injecting files ([a823a7d](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/a823a7dd8f5b331344fdbd554d899c52e7db55ee))

# [1.0.0-pre.9](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.8...v1.0.0-pre.9) (2022-11-23)


### Features

* **smilecdr:** automate setting JVMARGS ([6fcda8b](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/6fcda8b86ff8a67198b8fa208167ee9f6c5636f6))

# [1.0.0-pre.8](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/compare/v1.0.0-pre.7...v1.0.0-pre.8) (2022-11-22)


### Features

* **smilecdr:** set default replicas to 1 ([9788832](https://gitlab.com/smilecdr-techops/smile-dh-helm-charts/commit/97888327632c91dccc784a3e4891d9fcad5d58dc))

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
