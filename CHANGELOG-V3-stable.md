## [3.0.0](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/compare/v2.0.1...v3.0.0) (2025-05-13)

### ⚠ BREAKING CHANGES

* **smilecdr:** This will change many resource names. There has been a deprecation warning for a long time now to warn users of this impending change. If someone needs to revert to the oldResourceNaming, they can still manually set it. The deprecation notice has been updated to indicate that it will be completely removed in an upcoming release.
* **smilecdr:** Default version of Smile CDR changed to 2024.11.x

### Features

* **helm-internals:** add feature and version gate support ([476218e](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/476218e7d5f69d4ebfdbcbffd64442b911354d20))
* **smilecdr:** add support for node environment type ([df5c689](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/df5c689b87c2f386fa17d21254124f6213ae88e1))
* **smilecdr:** disable oldResourceNaming by default ([3251b7b](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/3251b7b4edc24e579fc81721e4e4d6525cfc2192))
* **smilecdr:** update Smile CDR to 2024.11.PRE-13 ([8c5d04c](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/8c5d04c1933495627456a2b71aab3c24a95d367c))

### Bug Fixes

* **smilecdr:** add support for Product Portal module ([c5a86d4](https://gitlab.com/smilecdr-public/smile-dh-helm-charts/commit/c5a86d495c17e084c9324ec5a1c592849376e799))
