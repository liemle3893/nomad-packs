[[- define "job_name" -]]
[[- if eq (default .base_app.app_name "") "" -]]
[[- .nomad_pack.pack.name -]]
[[- else -]]
[[- .base_app.app_name -]]
[[- end -]]
[[- end -]]

