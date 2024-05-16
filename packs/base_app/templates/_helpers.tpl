[[- define "job_name" -]]
[[- if eq (default (var "app_name" .) "") "" -]]
[[- meta "pack.name" . -]]
[[- else -]]
[[- var "app_name" . -]]
[[- end -]]
[[- end -]]

