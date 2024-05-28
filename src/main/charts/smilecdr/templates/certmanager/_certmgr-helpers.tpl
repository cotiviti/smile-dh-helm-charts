{{- /* Some Common Helper Templates for cert-manager */ -}}

{{- define "certmanager.issuers" -}}
  {{- $issuers := dict -}}
  {{- $tlsConfig := .Values.tls -}}

  {{- range $theIssuerName, $theIssuerSpec := $tlsConfig.certificateIssuers -}}
    {{- $issuer := dict -}}
    {{- $_ := set $issuer "createIssuer" false -}}

    {{- $_ := set $issuer "issuerType" (lower (default "cert-manager.io/v1" $theIssuerSpec.issuerType)) -}}
    {{- if not (contains $issuer.issuerType "cert-manager.io/v1") -}}
      {{- fail (printf "Issuer Type `%s` not supported. Use `cert-manager.io/v1`" $theIssuerSpec.issuerType ) -}}
    {{- end -}}

    {{- $_ := set $issuer "signingMethod" (lower (default "cluster-signed" $theIssuerSpec.signingMethod)) -}}
    {{- if not (contains $issuer.signingMethod "public-signed cluster-signed") -}}
      {{- fail (printf "Signing method `%s` not supported. Use `public-signed` or `cluster-signed`" $theIssuerSpec.signingMethod ) -}}
    {{- end -}}

    {{- $_ := set $issuer "defaultIssuer" $theIssuerSpec.defaultIssuer -}}
    {{- $_ := set $issuer "enabled" $theIssuerSpec.enabled -}}

    {{- if $theIssuerSpec.enabled -}}
      {{- /* Are we creating this issuer */ -}}
      {{- if or (not (hasKey $theIssuerSpec "createIssuer")) $theIssuerSpec.createIssuer -}}
        {{- $_ := set $issuer "createIssuer" true -}}
        {{- $_ := set $issuer "name" (default $theIssuerName $theIssuerSpec.caIssuerName) -}}

        {{- if eq $issuer.signingMethod "cluster-signed" -}}
          {{- /* Cluster signed
                 Create the following namespace-scoped Issuers (As opposed to ClusterIssuers)
                 * Self signed root issuer
                 * Root-issuer signed 'cluster-local' CA issuer
                   Note that "certmanager.certificates" will auto-create a matching certificate for this issuer
                 */ -}}

          {{- if eq "default" $theIssuerName -}}
            {{- /* Append '-ca' to the 'default' issuer so that its 'default' certificate does not clash with the 'default' certificate used by Smile CDR. */ -}}
            {{- /* $theIssuerName = printf "%s-ca" $theIssuerName */ -}}
            {{- $_ := set $issuer "name" (printf "%s-ca" $issuer.name) -}}
          {{- end -}}
          {{- $_ := set $issuer "selfSignedConfig" (default dict $theIssuerSpec.selfSignedConfig) -}}

          {{- /* Root self-signer issuer */ -}}
          {{- $rootIssuerName := default (printf "%s-root" $issuer.name) $theIssuerSpec.rootIssuerName -}}
          {{- if not ($theIssuerSpec.existingRootIssuer) -}}
            {{- $rootIssuer := dict "createIssuer" true -}}
            {{- $_ := set $rootIssuer "name" $rootIssuerName -}}
            {{- $_ := set $rootIssuer "resourceName" (include "certmanager.issuer.resourceName" (dict "issuerSpec" $rootIssuer "rootCTX" $)) -}}
            {{- /* $_ := set $rootIssuer "signingMethod" "selfSigned" */ -}}
            {{- $_ := set $rootIssuer "spec" (dict "selfSigned" dict) -}}
            {{- $_ := set $issuers $rootIssuerName $rootIssuer -}}
          {{- else -}}
            {{- $rootIssuerName = $theIssuerSpec.existingRootIssuer -}}
          {{- end -}}

          {{- /* Root signed CA issuer */ -}}
          {{- $_ := set $issuer "rootIssuer" $rootIssuerName -}}

          {{- /* We need to reference the Certificate for the cluster-signed CA
                 The "certmanager.certificate.issuerCert" template defines this certificate based on the CA issuer spec */ -}}
          {{- $issuerCertificate := (include "certmanager.certificate.issuerCert" (dict "issuerSpec" $issuer "issuers" dict "rootCTX" $) | fromYaml ) -}}

          {{- $_ := set $issuer "spec" (dict "ca" (dict "secretName" $issuerCertificate.spec.secretName)) -}}
        {{- else if eq $issuer.signingMethod "public-signed" -}}
          {{- /* Public signed
                Create single namespace-scoped Issuer (As opposed to ClusterIssuer)
                * No root issuer
                * No certificate required
                */ -}}

          {{- if not $theIssuerSpec.acmeSpec -}}
          {{- /* if not (hasKey $issuer "acmeSpec") */ -}}
            {{- fail (printf "Error creating public-signed issuer `%s`. You must provide an `acmeSpec` section." $theIssuerName) -}}
          {{- end -}}
          {{- /* $_ := set $issuer "acmeSpec" (default dict $theIssuerSpec.acmeSpec) */ -}}
          {{- $acmeSpec := $theIssuerSpec.acmeSpec -}}

          {{- /* Configure the private key for this issuer */ -}}
          {{- $pkSecretName := (printf "%s-key" $theIssuerName) -}}
          {{- $pkSecretResourceName := default (include "smilecdr.resourceName" (dict "rootCTX" $ "name" $pkSecretName)) $acmeSpec.privateKeySecretRef -}}
          {{- $_ := set $acmeSpec "privateKeySecretRef" (dict "name" $pkSecretResourceName) -}}

          {{- /* Configure the email and server */ -}}
          {{- $_ := set $acmeSpec "email" (required "You must provide an e-mail for your ACME Issuer configuration." $acmeSpec.email) -}}

          {{- /* We default to the lets encrypt staging server */ -}}
          {{- if not $acmeSpec.server -}}
            {{- /* fail "You must provide an `issuer.server`` if trying to use ACME certificates" */ -}}
            {{- $_ := set $acmeSpec "server" "https://acme-staging-v02.api.letsencrypt.org/directory" -}}
          {{- else if eq $acmeSpec.server "lets-encrypt-staging" -}}
            {{- $_ := set $acmeSpec "server" "https://acme-staging-v02.api.letsencrypt.org/directory" -}}
          {{- else if eq $acmeSpec.server "lets-encrypt-prod" -}}
            {{- $_ := set $acmeSpec "server" "https://acme-v02.api.letsencrypt.org/directory" -}}
          {{- end -}}

          {{- $nginxSolver := dict "http01" (dict "ingress" (dict "ingressClassName" "nginx")) -}}
          {{- $_ := set $acmeSpec "solvers" (default (list $nginxSolver) $acmeSpec.solvers) -}}
          {{- $_ := set $issuer "spec" (dict "acme" $acmeSpec) -}}
        {{- end -}}
        {{- /* If we are creating this issuer, we need to set an appropriate resource name. */ -}}
        {{- $_ := set $issuer "resourceName" (include "certmanager.issuer.resourceName" (dict "issuerSpec" $issuer "rootCTX" $)) -}}
      {{- end -}}
      {{- $_ := set $issuers $theIssuerName $issuer -}}
    {{- end -}}
  {{- end -}}
  {{- $issuers | toYaml -}}
{{- end -}}

{{- define "certmanager.issuer.resourceName" -}}
  {{- $rootCTX := get . "rootCTX" -}}
  {{- $issuerSpec := get . "issuerSpec" -}}
  {{- lower (printf "%s-%s" $rootCTX.Release.Name $issuerSpec.name) -}}
{{- end -}}

{{- define "certmanager.certificate.resourceName" -}}
  {{- $rootCTX := get . "rootCTX" -}}
  {{- $certificateSpec := get . "certificateSpec" -}}
  {{- lower (printf "%s-%s" $rootCTX.Release.Name $certificateSpec.name) -}}
{{- end -}}

{{- define "certmanager.certificate.issuerCert" -}}
  {{- $rootCTX := get . "rootCTX" -}}
  {{- $issuerSpec := get . "issuerSpec" -}}
  {{- $issuers := get . "issuers" -}}
  {{- $certificate := dict "spec" (dict "isCA" true) -}}

  {{- $certificateName := lower (default $issuerSpec.name $issuerSpec.selfSignedConfig.caIssuerCertificateName) -}}
  {{- $_ := set $certificate "name" $certificateName -}}
  {{- $_ := set $certificate "resourceName" (include "certmanager.certificate.resourceName" (dict "certificateSpec" $certificate "rootCTX" $rootCTX)) -}}

  {{- $defaultCommonName := (printf "%s-%s-cluster-local-signing-authority" $rootCTX.Release.Name $certificateName ) -}}
  {{- $_ := set $certificate.spec "commonName" (default $defaultCommonName $issuerSpec.selfSignedConfig.caIssuerCertificateCommonName ) -}}

  {{- /* This secret name needs to match the secret name for the certificate in "certmanager.certificates" */ -}}
  {{- $certSecretName := default (include "certmanager.certificate.secretName" (dict "certificate" $certificate "rootCTX" $rootCTX)) $issuerSpec.caIssuerSecretName -}}
  {{- $_ := set $certificate.spec "secretName" $certSecretName -}}

  {{- $caPrivateKeyDefaultConfig := dict "algorithm" "ECDSA" "size" 256 -}}
  {{- $_ := set $certificate.spec "privateKey" (default $caPrivateKeyDefaultConfig $issuerSpec.selfSignedConfig.caPrivateKeyConfig ) -}}

  {{- /* Get the Cluster self-signer Issuer resourceName for this certificate */ -}}
  {{- with get $issuers $issuerSpec.rootIssuer -}}
    {{- $caIssuerRef := dict "name" .resourceName "kind" "Issuer" "group" "cert-manager.io"  -}}
    {{- $_ := set $certificate.spec "issuerRef" (default $caIssuerRef $issuerSpec.selfSignedConfig.existingRootIssuer ) -}}
  {{- end -}}


  {{- $certificate | toYaml -}}
{{- end -}}

{{- define "certmanager.certificate.secretName" -}}
  {{- $rootCTX := get . "rootCTX" -}}
  {{- $certificate := get . "certificate" -}}
  {{- lower (printf "%s-%s-tls" $rootCTX.Release.Name $certificate.name) -}}
{{- end -}}

{{- define "certmanager.certificates" -}}
  {{- $certificates := dict -}}
  {{- $issuers := include "certmanager.issuers" . | fromYaml -}}
  {{- $tlsConfig := .Values.tls -}}

  {{- /* Use "smilecdr.services.enabledServices" instead of "smilecdr.services" to avoid circular dependency */ -}}
  {{- $services := include "smilecdr.services.enabledServices" . | fromYaml -}}

  {{- $defaultIssuer := (include "certmanager.defaultIssuer" $issuers) -}}

  {{- /* Add any certificates required by cluster-signed issuers */ -}}
  {{- range $theIssuerName, $theIssuerSpec := $issuers -}}
    {{- if $theIssuerSpec.enabled -}}
      {{- if contains (lower $theIssuerSpec.signingMethod) "cluster-signed" -}}
        {{- /* Generate the certificate for this 'root ca'
               It will be signed by the root signer */ -}}
        {{- $issuerCert := (include "certmanager.certificate.issuerCert" (dict "issuerSpec" $theIssuerSpec "issuers" $issuers "rootCTX" $) | fromYaml ) -}}
        {{- $_ := set $certificates $issuerCert.name $issuerCert -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- /* Configure and add remaining configured certs */ -}}
  {{- range $theCertificateName, $theCertificateSpec := $tlsConfig.certificates -}}
    {{- if $theCertificateSpec.enabled -}}
      {{- $certificate := dict "name" $theCertificateName "spec" dict -}}
      {{- $_ := set $certificate "resourceName" (include "certmanager.certificate.resourceName" (dict "certificateSpec" $certificate "rootCTX" $)) -}}

      {{- $defaultSecretName := include "certmanager.certificate.secretName" (dict "certificate" $certificate "rootCTX" $) -}}
      {{- $_ := set $certificate.spec "secretName" (default $defaultSecretName $theCertificateSpec.secretName) -}}

      {{- $_ := set $certificate "enabled" $theCertificateSpec.enabled -}}
      {{- $_ := set $certificate "defaultCertificate" $theCertificateSpec.defaultCertificate -}}
      {{- $_ := set $certificate "keystorePasswordd" $theCertificateSpec.keystorePassword -}}

      {{- $issuerName := "" -}}
      {{- if and $theCertificateSpec.issuerConfigName (ne (lower $theCertificateSpec.issuerConfigName) "default") -}}
        {{- $iss := $theCertificateSpec.issuerConfigName -}}
        {{- if not (hasKey $issuers $iss) -}}
          {{- fail (printf "Issuer `%s` specified in Certificate `%s` does not exist. Please choose from the available Issuers: %s" $iss $theCertificateName  (toString (keys $issuers))) -}}
        {{- end -}}
        {{- $issuerName = $theCertificateSpec.issuerConfigName -}}
      {{- else -}}
        {{- if not $defaultIssuer -}}
          {{- fail (printf "You have not specified an issuer for certificate `%s` and there are no default issuers available.\nPlease either configure a default Issuer or choose from the available Issuers: %s" $theCertificateName  (toString (keys $issuers))) -}}
        {{- end -}}
        {{- $issuerName = $defaultIssuer -}}
      {{- end -}}
      {{- /* Now we know the referenced issuer exists (or we are using the default issuer)
            Configure the certificate based on the kind of issuer being used */ -}}

      {{- $issuerSpec := get $issuers $issuerName -}}
      {{- $issuerRef := dict "name" $issuerSpec.resourceName "kind" "Issuer" "group" "cert-manager.io" -}}
      {{- $_ := set $certificate.spec "issuerRef" $issuerRef -}}

      {{- /* We need to create a compatible PKCS12 keystore in order to use in Smile CDR */ -}}
      {{- $keystores := dict "pkcs12" (dict "create" true) -}}

      {{- /* Configure the keystore secret*/ -}}
      {{- $keystorePasswordConfig := default (dict) $theCertificateSpec.keystorePassword -}}

      {{- if and (hasKey $keystorePasswordConfig "useSecret") (not $keystorePasswordConfig.useSecret) -}}
        {{- /* Secret is disabled - Currently not supported */ -}}
        {{- fail "Disabling secret is not currently supported for cert-manager generated keystores. (1)" -}}
        {{- $_ := set $keystorePasswordConfig "useSecret" false -}}
        {{- /* TODO: Add in the required `Certificate` spec changes once this has been implemented in cert-manager */ -}}
      {{- else -}}
        {{- $_ := set $keystorePasswordConfig "useSecret" true -}}
        {{- $secretKey := default "password" $keystorePasswordConfig.secretKey -}}
        {{- $keystorePasswordSecret := dict "key" $secretKey -}}

        {{- if $keystorePasswordConfig.secretRef -}}
          {{- /* Using an existing secret */ -}}
          {{- $_ := set $keystorePasswordConfig "createSecret" false -}}
          {{- $_ := set $keystorePasswordSecret "name" $keystorePasswordConfig.secretRef -}}
        {{- else -}}
          {{- /* Create a new secret */ -}}
          {{- $_ := set $keystorePasswordConfig "createSecret" true -}}
          {{- $resourceName := include "smilecdr.resourceName" (dict "rootCTX" $ "name" (printf "%s-tls-keystorepass" $theCertificateName)) -}}
          {{- $_ := set $keystorePasswordSecret "name" $resourceName -}}

          {{- $secretKey := default "password" $keystorePasswordConfig.secretKey -}}
          {{- $encodedValue := b64enc (default "changeit" $keystorePasswordConfig.valueOverride) -}}
          {{- $_ := set $keystorePasswordConfig "secretData" (dict "data" (dict $secretKey $encodedValue)) -}}
        {{- end -}}

        {{- $_ := set $keystorePasswordConfig "resourceName" $keystorePasswordSecret.name -}}
        {{- $_ := set $keystores.pkcs12 "passwordSecretRef" $keystorePasswordSecret -}}
      {{- end -}} {{- /* end of 'if use secret' */ -}}

      {{- $_ := set $certificate "keystorePasswordConfig" $keystorePasswordConfig -}}

      {{- /* TODO: Provide option to enable this. Not required, but should use if using cert-manager 1.14 or above. */ -}}
      {{- $certManagerKeystoreProfilesSupport := false -}}
      {{- if $certManagerKeystoreProfilesSupport -}}
        {{- $_ := set $keystores.pkcs12 "profile" "Modern2023" -}}
      {{- end -}}

      {{- $_ := set $certificate.spec "keystores" $keystores -}}

      {{- /* Add any required dnsNames to the certificate.
            The names added will depend on whether this is going to be a publically signed cert
            or a cluster-signed cert */ -}}
      {{- $dnsNames := list -}}

      {{- /* Define overridable main hostname */ -}}
      {{- $hostname := default $.Values.specs.hostname $theCertificateSpec.hostnameOverride -}}

      {{- /* Always add hostname (note this is removed in cluster-signed section if `hostnameEnabled: false` is set) */ -}}
      {{- $dnsNames = append $dnsNames $hostname -}}

      {{- /* Add any extra hostnames */ -}}
      {{- /* Be careful here if using public CA as these need to be automatically verifiable host names */ -}}
      {{- if and (hasKey $theCertificateSpec "extraHostnames") (ge (len $theCertificateSpec.extraHostnames) 1) -}}
        {{- $dnsNames = concat $dnsNames $theCertificateSpec.extraHostnames -}}
      {{- end -}}

      {{- if eq $issuerSpec.signingMethod "cluster-signed" -}}
        {{- /* We are using a cluster-signed issuer, so we can add all the local kubernetes host names. */ -}}
        {{- $namespace := $.Release.Namespace -}}

        {{- /* Add main hostname unless disabled with `hostnameEnabled: false` */ -}}
        {{- if and (hasKey $theCertificateSpec "hostnameEnabled") (not $theCertificateSpec.hostnameEnabled) -}}
          {{- /* hostname is explicitly disabled. Remove it. */ -}}
          {{- $dnsNames = without $dnsNames $hostname -}}
        {{- end -}}

        {{- if eq $theCertificateSpec.wildcardLevel "cluster" -}}
          {{- $dnsNames = append $dnsNames "*.cluster.local" -}}
        {{- else if eq $theCertificateSpec.wildcardLevel "service" -}}
          {{- $dnsNames = append $dnsNames "*.svc.cluster.local" -}}
        {{- else if eq $theCertificateSpec.wildcardLevel "namespace" -}}
          {{- $dnsNames = append $dnsNames (printf "*.%s.svc.cluster.local" $namespace) -}}
        {{- end -}}

        {{- if $theCertificateSpec.localhostEnabled -}}
          {{- $dnsNames = append $dnsNames "localhost" -}}
        {{- end -}}

        {{- $useFullHostnames := true -}}
        {{- if $useFullHostnames -}}
          {{- range $theServiceName, $theService := $services -}}
            {{- /* Only add service name if it uses the current certificate */ -}}
            {{- /* The validation here would be redundant as it's already done in "smilecdr.services"
                   so we can just go ahead and use the tls config for the service. */ -}}
            {{- if $theService.tls.enabled -}}
              {{- $includeServiceNames := false -}}
              {{- if eq $theCertificateName $theService.tls.tlsCertificate -}}
                {{- /* If current certificate name matches the service certificate name */ -}}
                {{- $includeServiceNames = true -}}
              {{- else if and $theCertificateSpec.defaultCertificate (eq (lower $theService.tls.tlsCertificate) "default") -}}
                {{- /* If current certificate is the default and service uses the default */ -}}
                {{- $includeServiceNames = true -}}
              {{- end -}}
              {{- if $includeServiceNames -}}
                {{- $dnsNames = append $dnsNames (printf "%s.%s.svc.cluster.local" $theService.resourceName $namespace) -}}
                {{- $dnsNames = append $dnsNames (printf "%s.%s.svc" $theService.resourceName $namespace) -}}
                {{- $dnsNames = append $dnsNames (printf "%s.%s" $theService.resourceName $namespace) -}}
                {{- $dnsNames = append $dnsNames (printf "%s" $theService.resourceName) -}}
              {{- end -}}
            {{- end -}}
          {{- end -}}
        {{- end -}}
      {{- else if eq $issuerSpec.signingMethod "public-signed" -}}
        {{- /* We are using a public-signed issuer, so we can only add the valid hostname.
            This is already done further up */ -}}
      {{- end -}}
      {{- $_ := set $certificate.spec "dnsNames" (uniq $dnsNames) -}}

      {{- $_ := set $certificates $certificate.name $certificate -}}
    {{- end -}}
  {{- end -}}

  {{- $certificates | toYaml -}}
{{- end -}}

{{- /* Helper to find the name of the default Issuer configuration */ -}}
{{- define "certmanager.defaultIssuer" -}}
  {{- $defaultIssuer := "" -}}
  {{- range $theIssuerName, $theIssuerSpec := . -}}
    {{- if $theIssuerSpec.enabled -}}
      {{- if $theIssuerSpec.defaultIssuer -}}
        {{- if eq $defaultIssuer "" -}}
          {{- $defaultIssuer = $theIssuerName -}}
        {{- else -}}
          {{- /* It's already set, so there must be multiple default listeners. */ -}}
          {{- fail (printf "You cannot set multiple Issuers to be the default. `defaultIssuer` is set for `%s` and `%s`" $defaultIssuer $theIssuerSpec.defaultIssuer) -}}
        {{- end -}}

      {{- end -}}

    {{- end -}}
  {{- end -}}
  {{- $defaultIssuer -}}
{{- end -}}

{{- /* Helper to find the name of the default Issuer configuration */ -}}
{{- define "certmanager.defaultCertificate" -}}
  {{- $defaultCertificate := "" -}}
  {{- range $theCertificateName, $theCertificateSpec := . -}}
    {{- if $theCertificateSpec.enabled -}}
      {{- if $theCertificateSpec.defaultCertificate -}}
        {{- if eq $defaultCertificate "" -}}
          {{- $defaultCertificate = $theCertificateName -}}
        {{- else -}}
          {{- /* It's already set, so there must be multiple default listeners. */ -}}
          {{- fail (printf "You cannot set multiple Issuers to be the default. `defaultCertificate` is set for `%s` and `%s`" $defaultCertificate $theCertificateName) -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{- $defaultCertificate -}}
{{- end -}}


{{- /*
Define cert-manager related volumes requird by Smile CDR pod
*/ -}}
{{- define "certmanager.volumes" -}}
  {{- $volumes := list -}}

  {{- range $theCertificateName, $theCertificate := .Values.certificates -}}
    {{- if and $theCertificate.enabled (($theCertificate.spec.keystores).pkcs12).create -}}

      {{- $volumeName := (printf "%s-tls-keystore" $theCertificateName) -}}
      {{- $secretName := $theCertificate.spec.secretName -}}

      {{- $keystoreSecretKey := "keystore.p12" -}}
      {{- $keystoreFileName := printf "%s-tls-keystore.p12" $theCertificateName -}}
      {{- $secretProjection := dict "secretName" $secretName "items" (list (dict "key" $keystoreSecretKey "path" $keystoreFileName)) -}}

      {{- $certVolume := dict "name" $volumeName "secret" $secretProjection -}}
      {{- $volumes = append $volumes $certVolume -}}
    {{- end -}}
  {{- end -}}
  {{- $volumes | toYaml -}}
{{- end -}}

{{- /*
Define cert-manager related volume mounts requird by Smile CDR pod
*/ -}}
{{- define "certmanager.volumeMounts" -}}
  {{- $volumeMounts := list -}}

  {{- range $theCertificateName, $theCertificate := .Values.certificates -}}
    {{- if and $theCertificate.enabled (($theCertificate.spec.keystores).pkcs12).create -}}
      {{- $volumeName := (printf "%s-tls-keystore" $theCertificateName) -}}
      {{- $keystoreFileName := printf "%s-tls-keystore.p12" $theCertificateName -}}
      {{- $volumeMount := dict "name" $volumeName -}}
      {{- $_ := set $volumeMount "mountPath" (printf "/home/smile/smilecdr/classes/tls/%s" $keystoreFileName) -}}
      {{- $_ := set $volumeMount "subPath" $keystoreFileName -}}
      {{- $_ := set $volumeMount "readOnly" true -}}
      {{- $volumeMounts = append $volumeMounts $volumeMount -}}
    {{- end -}}
  {{- end -}}
  {{- $volumeMounts | toYaml -}}
{{- end -}}

{{- /*
Define cert-manager related env vars
*/ -}}
{{- define "certmanager.envVars" -}}
  {{- $envVars := list -}}

  {{- range $theCertificateName, $theCertificate := .Values.certificates -}}
    {{- if and $theCertificate.enabled (($theCertificate.spec.keystores).pkcs12).create -}}
      {{- /* TODO: Only include the keystore password if it is used in this cdr node */ -}}
      {{- $env := dict "name" (upper (printf "%s_TLS_KEYSTORE_PASS" $theCertificateName)) -}}

      {{- $keystorePasswordConfig := $theCertificate.keystorePasswordConfig -}}
      {{- if $keystorePasswordConfig.useSecret -}}
        {{- $secretName := $keystorePasswordConfig.resourceName -}}
        {{- $secretKey := default "password" $keystorePasswordConfig.secretKey -}}
        {{- $_ := set $env "valueFrom" (dict "secretKeyRef" (dict "name" $secretName "key" $secretKey)) -}}
      {{- else -}}
        {{- /* Secret is disabled - Currently not supported */ -}}
        {{- fail "Disabling secret is not currently supported for cert-manager generated keystores. (2) " -}}
        {{- $_ := set $env "value" (default "changeit"  $keystorePasswordConfig.valueOverride) -}}
      {{- end -}}
      {{- $envVars = append $envVars $env -}}
    {{- end -}}
  {{- end -}}
  {{- $envVars | toYaml -}}
{{- end -}}
