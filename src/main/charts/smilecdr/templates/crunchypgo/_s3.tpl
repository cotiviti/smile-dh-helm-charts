{{/* Allow for S3 secret information to be stored in a Secret */}}
{{- define "postgres.s3" -}}
{{- $repoName := coalesce .s3.repo (printf "repo%d" add .index 1 ) -}}
[global]
{{- if or .s3.key .s3.keySecret .s3.encryptionPassphrase }}
  {{- if .s3.key }}
{{ $repoName }}-s3-key={{ .s3.key }}
  {{- end }}
  {{- if .s3.keySecret }}
{{ $repoName }}-s3-key-secret={{ .s3.keySecret }}
  {{- end }}
  {{- if .s3.encryptionPassphrase }}
{{ $repoName }}-cipher-pass={{ .s3.encryptionPassphrase }}
  {{- end }}
{{- else }}
{{ $repoName }}-s3-key-type=web-id
{{- end }}
{{- end }}
