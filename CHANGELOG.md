# [1.1.0](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v1.0.0...v1.1.0) (2024-08-08)


### Bug Fixes

* **smilecdr:** fix smileutil command ([c7efcbe](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/c7efcbef35e69b2fbce8a52d8435bde5dbfb8f10))
* **smilecdr:** set java.io.tmpdir to correct location ([7b85499](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/7b854999f9079e72cd341f4e56fa39800172083f))


### Features

* **smilecdr:** allow ephemeral volume configuration ([1f74351](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/1f74351d1947c50ffcfdab75d1457812827c7f8f))
* **smilecdr:** update volumeConfig spec ([29390f7](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/29390f768afff4e81a6a56d6312dc7abb2cafb65))

# 1.0.0 (2024-07-03)


### Bug Fixes

* **common:** remove `chart.shortname` template ([f7a0a8b](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/f7a0a8b124c8ddac280c73664f426b068252a6f2))
* **kafka:** fix Kafka Admin pod IAM auth ([6a84d77](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/6a84d7738bae6303cf16cb696a6d833c88ff0436))
* **kafka:** update kafka admin pod scripts ([45a6136](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/45a61365851dc5fc095e23bc9cf55cde781ace39))
* **pmp:** add per-component imagePullSecrets logic ([880c74e](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/880c74e229e0799dc0fc255859731f32d3856185))
* **smilecdr:** add config sanity checks ([eea5ae6](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/eea5ae60da1a7fb9ce2ac173d15e365c742f1de2))
* **smilecdr:** add error checking for mapped files ([95b82d0](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/95b82d0a468942fff15b2e6335158c8d0082da72))
* **smilecdr:** add preStop delay ([2d31c8c](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/2d31c8c6603bdc23240d7851b7fd4a76f9e39db9))
* **smilecdr:** allow hierarchical config ([f664d5e](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/f664d5e9727d84c4a57e8e928bd547c9368e8571))
* **smilecdr:** allow quoted config entries ([201d69b](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/201d69ba6455ad81d83df6135fb00a216ebfb86f))
* **smilecdr:** allow specifying db name ([4d4cd84](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/4d4cd8410922f8edd29896e3754d9ec947c7874e))
* **smilecdr:** auto-set s3 cp recursive option ([045463d](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/045463d66c7c6f3615a0fba2751821c380b714cf))
* **smilecdr:** change crunchydata resource names ([ad7ee34](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/ad7ee3483149e5b030410dd3c20e1aaf27699b9a))
* **smilecdr:** change objectAlias naming logic ([ade3f22](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/ade3f22fde28f2d32bbc6699cceb1697b866a33a))
* **smilecdr:** correct spelling of license ([25dd99a](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/25dd99a52fb054aa8e6662ff871a3a11f4657203))
* **smilecdr:** correct the field for image secrets ([ff7c819](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/ff7c8190367de8577310e010e05f74b9f312a9e5))
* **smilecdr:** fix base_url for hybrid provider ([e80367d](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/e80367dd59db59639c0f261edf29796f98751a3d))
* **smilecdr:** fix ConfigMap reference in volume ([5cc81e8](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/5cc81e8c016d7d708ab8d8df39b147665406eec4))
* **smilecdr:** fix database enablement comparison ([82c8975](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/82c89759f84fde2445d9ff6ba8b8310d0089a677))
* **smilecdr:** fix DB_PORT in default modules ([ac5b592](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/ac5b5921fcd0444fc66f9d1c9f4a14df86ca794f))
* **smilecdr:** fix disableAutoJarCopy option ([03d5163](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/03d5163f3faa971f869167e54af375a64594ed54))
* **smilecdr:** Fix IAM Jar version in Kafka admin ([f5048f1](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/f5048f13117271d3827b310d1b843d7856c90fd0))
* **smilecdr:** fix ingress annotation overrides ([78d254e](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/78d254e3f891a2ae03b9f181a2da9e965017269c))
* **smilecdr:** fix k8s resource labels ([6378fe0](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/6378fe09908748e5bd56aa27a2d73a74cb6db302))
* **smilecdr:** fix kafka configs with IAM auth ([170a14c](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/170a14c3c7cfb288f92edbcc35edca1366404191))
* **smilecdr:** fix key names in env vars ([81defae](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/81defaef33a5fa1f1cadfc4b14f68896f6b7cbff))
* **smilecdr:** fix key names in k8s secret ([b84760a](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/b84760aa4df7999c5c151eda437649511c11d88b))
* **smilecdr:** fix licence module settings ([ceab69d](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/ceab69d596e8986b7d74cc0cd821351ecb7c3c9f))
* **smilecdr:** fix paths for initcontainer ([ce17551](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/ce17551b893d14a613ffad8875839ff5086f3f07))
* **smilecdr:** fix quoting of ingress annotations ([7252dff](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/7252dffe59ddbc9352d7f3ea517903a277dc4ffe))
* **smilecdr:** fix reference to configmap data ([8a61d36](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/8a61d36513ccbcab3637c1d0baa277e077f3423f))
* **smilecdr:** fix route rendering for AppSphere ([903b00e](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/903b00e8788c072e5ec6a247203386297d88e90e))
* **smilecdr:** fix s3 copy for customerlib ([66ea90a](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/66ea90a2c13efc909bf62354475783670bed77ec))
* **smilecdr:** fix s3 copy with readonly rootfs ([f7a6a12](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/f7a6a12ab103e4b8cd82f94e5b393896134c14de))
* **smilecdr:** fix secret reference keys ([2f6411b](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/2f6411ba5b81fc7139d1335b6b4935405e27556f))
* **smilecdr:** fix SSCI resource naming ([0e926f5](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/0e926f5bc78052b5800a7233f19d3a2bcce1c40b))
* **smilecdr:** fix validate topic logic ([c08e65c](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/c08e65cd52e2ba8abc862811436f350af886d343))
* **smilecdr:** fix value for grace period ([54686f7](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/54686f7dfc6680b57748c57b6a94ae73ff31850c))
* **smilecdr:** follow redirects for curl ([698d045](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/698d04529675f60788839002c9f1a5c55f3718d9))
* **smilecdr:** force lower case in resource names ([6d1e4aa](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/6d1e4aa1ff27d7541f370859651047065eece060))
* **smilecdr:** improve handling of issuer.url ([9f0976c](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/9f0976c6ea225ef9fd2f434744b60b8a62650f9f))
* **smilecdr:** improve modules include logic ([7bfad46](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/7bfad466777162da9a9f82fc0f69c0b80a0ec9eb))
* **smilecdr:** multiple init-pull containers ([80ced73](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/80ced73548a612e1580c0204f55cd170301ed595))
* **smilecdr:** Remove duplicate env vars ([8284743](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/8284743a31da915660aefae8054abbd60adf05fd))
* **smilecdr:** remove image reference ([54ff0b6](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/54ff0b663dae638ed672596057d8c058f702f4ff))
* **smilecdr:** remove short-circuit dependency ([9af24c2](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/9af24c2c3f9bde89f8d26b44735f3ead36a51bdd))
* **smilecdr:** update default modules ([f83ff90](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/f83ff9089e4c93555efcd25d9545f4b3fe188ab6))
* **smilecdr:** update initContainer configurations ([c974af5](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/c974af5e398db2b840cded466ca68eb6dea38d9f))
* **smilecdr:** update keystore secret creation and naming ([beb397f](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/beb397f2709f9f1372556125edfef36fbb7ba207))
* **smilecdr:** update Strimzi schema ([3b65726](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/3b65726f3e2cee286d5a0c4163f275cfcdab2e3d))
* **smilecdr:** update transaction module name ([f4472ca](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/f4472cac24ff61a95b6e5a149f7b41d47690b62c))
* **smilecdr:** update uid for curl images ([a7cb4de](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/a7cb4de7b48d05aba7f806ab6383c03c6b6b3a91))
* **smilecdr:** use camelCase for `useDefaultModules` ([a0178ac](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/a0178ac5e576cb03f3ce8235fc4ceef738914606))
* **smilecdr:** use correct labels for Kafka admin ([fce2935](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/fce2935fbd4237240a36ea67ae2d085fcf97d2fa))
* **smilecdr:** use provided tag for initcontainer ([2f68eb6](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/2f68eb6b449fee56a4964b2a204ef5703434f39f))


### Features

* **common:** add Smile DH common library chart ([46a3e67](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/46a3e673a581963722edc3007b4019146d1a6e7b))
* **pgo:** add more configurability to crunchydata PG CRD ([91591e0](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/91591e0c9b268b6dd53ee834782442082fd8dc4e))
* **pmp:** add pmp chart ([d52cc0c](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/d52cc0c9822849b9d1aae3ad77884a75b77c8199))
* **pmp:** add pmp-directus chart ([f8c0b1e](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/f8c0b1e0bc9d0d1893fa9cddfac820c83e9e4cc7))
* **pmp:** add pmp-keycloak chart ([10541a4](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/10541a44e473e1a954bbc3c5dcf00b302f7cffa0))
* **repo:** initial Commit ([0abcb74](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/0abcb74f05d03311fd4d4eaf9e928ca5975f6551)), closes [#68834381](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/issues/68834381)
* **smilecdr:** add AMQ support ([f724142](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/f72414226307dd8d038f8553de50c47ea1c6aed7))
* **smilecdr:** add argocd feature ([75a4874](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/75a4874bd2da5dede8630babe586143f4f1848b1))
* **smilecdr:** add autoscaling support ([e63838d](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/e63838d0b73b4a4a1de6c26c92a3a829c051603c))
* **smilecdr:** add back default tag functionality ([270a8e4](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/270a8e4d59d42b30734d95d71206a636cc0f18ae))
* **smilecdr:** add cert-manager support ([17e3be5](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/17e3be5b8c3861129f01fde3240b005b71266a0b))
* **smilecdr:** add common labels to all resources ([7e2a45c](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/7e2a45cbf17fe9b0068517fb0ca43b4cefac3d4a))
* **smilecdr:** add config locking options ([351d48d](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/351d48d5425ddac08d3e4601843ca281191bf7e2))
* **smilecdr:** add configurable logging ([20624ec](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/20624ec51a05dfdb631c1f6363fa0da0df558d5b))
* **smilecdr:** add database properties mode ([bb0b614](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/bb0b614c641c4f18b71a1f2dae7df17e799ea64b))
* **smilecdr:** add db suffix configuration ([ddf3b63](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/ddf3b63f58798c41c850ee8c19b5a0bcbeb17eb1))
* **smilecdr:** add external module files support ([46fe6a5](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/46fe6a5a8ab5d423bde335b1f576a1ea5fc94e34))
* **smilecdr:** add HL7v2 support ([05d5579](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/05d5579c1e61ad01a0edb549f53aad6119da6cf4))
* **smilecdr:** add IAM auth for RDS support ([881ee35](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/881ee35a01619097ca8ad00ea2506c96b64d7f16))
* **smilecdr:** add ingress TLS support ([75b3955](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/75b39559aa7bdb4db4ae9cb09348e123d089fa6b))
* **smilecdr:** add init-sync for customerlib ([099cb57](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/099cb575baee438b383a008dde1b0937dc95a24d))
* **smilecdr:** Add instrumentation support ([2583c81](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/2583c816db3f4819b8fb49384d9c41ee0093d001))
* **smilecdr:** add Kafka admin pod ([c9f0493](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/c9f0493fb94e98af7d8cb8bd88f0a98b8725b927))
* **smilecdr:** add Kafka password auth ([bc805fa](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/bc805fadec5228757219524ffd450118f26aedd9))
* **smilecdr:** add license support ([3c429d8](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/3c429d822754bceccebfb1783120b876cbcfc8b1))
* **smilecdr:** add multi-node configuration ([29848e7](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/29848e7df2fa088675e43899fa8cc6cffe521a13))
* **smilecdr:** add name override for CrunchyPGO ([0ba704c](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/0ba704c842d82652b51d8e62c9577f540e763e03))
* **smilecdr:** add pod disruption budget ([88f80ad](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/88f80adcd37a5ba28953dc3e70737f715c89fa49))
* **smilecdr:** add readiness probe ([ea11897](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/ea118976c425aa4736faf17df431ae218d1588c6))
* **smilecdr:** add redeploy on config changes ([9add457](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/9add457480d01b7fb4576664ad4cecde0b50e90c))
* **smilecdr:** add Secrets Store CSI support ([ca9318d](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/ca9318de5f00d9420f02dfe011471088caf92e4a))
* **smilecdr:** add service annotations for ALB ([1d9b82b](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/1d9b82b735cc9474e8ffbc2ad735a79921822553))
* **smilecdr:** add startup probe ([9697849](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/96978493fddbd4af2b6f3343c9c01739efbf3192))
* **smilecdr:** add support for 2023.02 release ([7c583de](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/7c583dec7a70a9ba7f0677df1afcb175a2386f49))
* **smilecdr:** add support for Alpine3 base image ([dc7e960](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/dc7e960d3978723238fbd9e91bee565385b2a6f6))
* **smilecdr:** add support for deploying postgres ([db8004b](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/db8004b92a04d511a541d740d565ec73ce267c83))
* **smilecdr:** add support for extra secrets ([0df7ce8](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/0df7ce8b3f155fa11e3cc64049c81bfa8d7616e9))
* **smilecdr:** add support for IRSA (IAM roles) ([120a0e5](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/120a0e5ed348add1d8f1e324b9a8cc281678d832))
* **smilecdr:** add support for multiple ingresses ([91485d6](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/91485d68a4889c1e0f2d875eda1e9480499af029))
* **smilecdr:** add support for strimzi kafka ([87d7ccc](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/87d7ccca8aabfbc76e963bd2467ce5d2f4ebe216))
* **smilecdr:** add support for tolerations ([b02059b](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/b02059b760abacf8c0f24d25f9a8cdd32f8aaa00))
* **smilecdr:** allow configurable pod topology ([349bf32](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/349bf32e67de906b97a86a11066f2f85578e394f))
* **smilecdr:** allow custom image repos ([033825a](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/033825a395a7413def09682e7b0ddd70058060bd))
* **smilecdr:** allow custom startup probe timings ([5bfabc5](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/5bfabc51e5a04ac3fe6efd2c1c251583d91689b0))
* **smilecdr:** allow disabling of module ingress ([ca3011b](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/ca3011bca4b0f0b2eaa6fa1c21bb24dad3dba550))
* **smilecdr:** allow extra env vars and volumes ([9d53ec8](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/9d53ec82acb326792837881ba00a05d047da8a4f))
* **smilecdr:** allow global endpoint configurations ([1fe5b0e](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/1fe5b0ee94af025c584138c589633bcc8cb2c4e6))
* **smilecdr:** allow using existing certificate Issuers ([106daf2](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/106daf294862ba2aabd34d2678c3d514047c199b))
* **smilecdr:** automate setting JVMARGS ([3d82f5c](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/3d82f5c8fd4e42c4d48b182d996d84d13b8a4e98))
* **smilecdr:** change db secret config ([8069b77](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/8069b77d4920ef64154eca12d06c4c788241a831))
* **smilecdr:** configure rolling deployments ([8acd271](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/8acd271111d4b9d02ec5981ba1f1f2c5cc529089))
* **smilecdr:** copy files from external location ([ea2710f](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/ea2710f406d43b610e7cfa41b2d8e9859f9536d2))
* **smilecdr:** disable crunchypgo ([a2a4e32](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/a2a4e32f624a5d348d8bf03c5ebcd90dea8dd690))
* **smilecdr:** disable SNI verification with ALB ([b196587](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/b196587e95a1748928a80f58cab7f8a8ee19496d))
* **smilecdr:** enable creation of ACME issuers ([f44e770](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/f44e770a141f32165920915e322bdd7510e60f31))
* **smilecdr:** enforce TLSv1.3 encryption ([49cd696](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/49cd69673df09a90baa0762f108b1db9868ba400))
* **smilecdr:** improve CrunchyData integration ([85d7da5](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/85d7da549cd5758bd2d356d09212e728e5f6f88a))
* **smilecdr:** improve readiness probe definition ([25273a9](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/25273a9e00fc4d406856edd4c347798e29a50404))
* **smilecdr:** improve secrets error handling ([8df9476](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/8df9476ca34df796cbc833b9ff67e9bc8d4c6f35))
* **smilecdr:** improve warnings for chart errors ([b50e54e](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/b50e54ec10caf01a537e96d8d630f227272efcdc))
* **smilecdr:** make image secret required ([e068330](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/e068330a9e2b1b890b6008ab5790a5bfa0180c91))
* **smilecdr:** make readiness probe configurable ([e83a98e](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/e83a98e1c411794aaa4001e79f44633e643f1810))
* **smilecdr:** normalize resource names ([98020a7](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/98020a7d4900311c6034c7c481131654e9d16d61))
* **smilecdr:** refactor image pull secrets ([c7d376c](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/c7d376ceca98ae14f275227a4430a3e1e8063306)), closes [#78](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/issues/78)
* **smilecdr:** remove extra labels from default values ([8110939](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/8110939e6e4a4ea75720ace9030dd16bd3b3d02d))
* **smilecdr:** remove hard coded entries from ConfigMap ([7d24665](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/7d24665aea477ed9acf4542ef88720c91232ac6b))
* **smilecdr:** rework Kafka configuration ([d27a00b](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/d27a00b3dd09d42bf62e27d07f957344e978d551))
* **smilecdr:** set default replicas to 1 ([bc74a1f](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/bc74a1f86a0973405e216f95ff0e112454cdacef))
* **smilecdr:** support injecting files ([a02cd3f](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/a02cd3f5d05c231d9091f468c0635d63d9854c82))
* **smilecdr:** support multiple databases ([8b0ee32](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/8b0ee32eb7844385985fe60193ce945060d1a971))
* **smilecdr:** update application version ([8bd06b4](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/8bd06b4ae355681f0cd7d51ed5a4b1276363442e))
* **smilecdr:** update CDR version and modules ([862d4da](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/862d4daeeb3f7a8de0e206da21b1b1098eae2ad0))
* **smilecdr:** update consumer properties ([c1978e5](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/c1978e59d8bb088b433917da5edcd78db1b4d2f0))
* **smilecdr:** update default ELB security policy ([0e49cc0](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/0e49cc09343bbe2882b08a94b1a7602cbf07d7a9))
* **smilecdr:** update Ingress definition logic ([afed28b](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/afed28b77c4cb74c0785f9e54347de846748bfe9))
* **smilecdr:** update ingress logic and docs ([affff39](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/affff3956865d817f14988ea420bc61e1b5f38ad))
* **smilecdr:** update JVM tuning params ([b0c746b](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/b0c746be88be26e235f103cf94bc6222a248b93c))
* **smilecdr:** update k8s secrets mechanism ([0733b5d](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/0733b5d3f3b5f4fcec4be4ce121bb230948e4ce6))
* **smilecdr:** update Secrets mechanisms ([158f2c3](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/158f2c3da94206abe8945e60c064ba20d8d53ec7))
* **smilecdr:** update Smile CDR version 2024.05.R03 ([75dc81d](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/75dc81db3bc1f46160ba3747ec8be07f2f990462))
* **smilecdr:** update to latest Smile CDR version ([db1caae](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/db1caaede8a95a4e82f3e62d0ee24f55494b278f))
* **smilecdr:** update to latest Smile CDR version ([d9c0240](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/d9c02408149cafe4c3e8c4dfea3ca30eb6d46041))
* **smilecdr:** Update to Smile CDR 2023.05.R01 ([99aa74d](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/99aa74d568b35504e3955ce65fdce922428db99f))
* **smilecdr:** Update to Smile CDR 2023.05.R01 ([bf89b79](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/bf89b79b879a6e02f365e50e4829db91822fd566))
* **smilecdr:** Update to Smile CDR 2023.05.R02 ([e7362b8](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/e7362b88ebf1fda24779baaff94b2e8dd6f54c4c))
* **smilecdr:** Update to Smile CDR 2023.08.R01 ([d3b33f1](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/d3b33f1a812c6c5a5a4261175921a91c23b0b971))


### BREAKING CHANGES

* **smilecdr:** Default version of Smile CDR is updated to 2024.05.R03
* **smilecdr:** - If you currently specify a source path without a trailing slash, it will no longer try to recursively copy the files.
* **smilecdr:** This affects the default consumer properties
configured in Smile CDR.
* **smilecdr:** Existing Kafka/Strimzi configurations have changed. As
they were previously untested, the required changes may be unpredictable.
Please refer to the docs to configure Kafka.
* **smilecdr:** Deprecation warning - Values files must be updated to use
`image.imagePullSecrets` instead of `image.credentials`.
* **smilecdr:** This change affects the default module configuration.
* **smilecdr:** Values file needs to be updated if using sscsi for DB
secrets
* **smilecdr:** - This updates the SmileCDR version
* **smilecdr:** Now uses `nginx-ingress` instead of
`aws-lbc-nlb` for specifying Nginx Ingress Controller
