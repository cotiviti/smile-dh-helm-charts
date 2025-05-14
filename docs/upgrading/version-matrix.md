# Supported Versions
Before choosing a version of the Smile CDR Helm Chart or the core Smile CDR product, refer to the version tables below to ensure that you are using a compatible combination.

## Current Stable Version
* Smile CDR Helm Chart: `{{ current_helm_version }}`
* Smile CDR: `{{ current_smile_cdr_version }}`

<!-- ## Next Upcoming Major Version
* Smile CDR Helm Chart: `{{ next_smile_cdr_version }}`
* Smile CDR: `{{ next_smile_cdr_version }}` -->

## Stable Releases
These are the current stable releases, published in the `stable` release channel
<!-- {{ version_matrix_stable }} -->

| Helm Chart Version | Default Smile CDR Version | Oldest Supported Smile CDR Version |
| ------------------ | ------------------------- | ---------------------------------- |
{{ previous_versions_table }}

## Upcoming Release Previews
These future versions will be published in one of the prerelease channels
<!-- {{ version_matrix_devel }} -->

| Helm Chart Version  | Release Channel | Default Smile CDR Version | Oldest Supported Smile CDR Version |
| ------------------  | --------------- | ------------------------- | ---------------------------------- |
| v{{ pre_release_helm_version }} | `pre-release` | `{{ pre_release_smile_cdr_version }}` | `{{ pre_release_smile_cdr_version_min }}` |
| v{{ next_major_helm_version }}  | `next-major`  | `{{ next_major_smile_cdr_version }}`  | `{{ next_major_smile_cdr_version_min }}`  |
| v{{ beta_helm_version }}        | `beta`        | `{{ beta_smile_cdr_version }}`        | `{{ beta_smile_cdr_version_min }}`        |
| v{{ alpha_helm_version }}       | `alpha`       | `{{ alpha_smile_cdr_version }}`       | `{{ alpha_smile_cdr_version_min }}`       |
