job "[[ template "job_name" . ]]" {
  region      = "[[ .base_app.region ]]"
  datacenters = [ [[ range $idx, $dc := .base_app.datacenters ]][[if $idx]],[[end]][[ $dc | quote ]][[ end ]] ]
  type = "service"
  [[ range $c := .base_app.constraints ]]
  constraint {
    [[- if $c.attribute ]]
    [[- if (gt (len $c.attribute) 0)]]
    attribute = [[$c.attribute | quote]] [[end]][[end]]
    [[- if $c.operator ]]
    [[- if (gt (len $c.operator) 0)]]
    operator = "[[$c.operator]]"[[end]][[end]]
    [[- if $c.value ]]
    [[- if (gt (len $c.value) 0)]]
    value = "[[$c.value]]"[[end]][[end]]    
  }
  [[end]]
  spread {
    attribute = node.datacenter
    weight    = 100
  }  

  group "app" {
    count = [[or .base_app.count 1]]
    update {
      auto_revert = [[ or .base_app.update.auto_revert true ]]
      auto_promote = [[ or .base_app.update.auto_promote false ]]
      max_parallel = [[ or .base_app.update.max_parallel 1 ]]
      canary     = [[ or .base_app.update.canary 0 ]]
      min_healthy_time = "[[ or .base_app.update.min_healthy_time "10s" ]]"
      healthy_deadline = "[[ or .base_app.update.healthy_deadline "3m" ]]"
      progress_deadline = "[[ or .base_app.update.progress_deadline "10m" ]]"
      stagger = "[[ or .base_app.update.stagger "30s" ]]"
    }
    migrate {
      max_parallel     = [[ or .base_app.migrate.max_parallel 1 ]]
      health_check     = "[[ or .base_app.migrate.health_check "checks" ]]"
      min_healthy_time = "[[ or .base_app.migrate.min_healthy_time "10s" ]]"
      healthy_deadline = "[[ or .base_app.migrate.healthy_deadline "5m" ]]"
    }    
    network {
      [[ range $p := .base_app.ports -]]
      port "[[ $p.name ]]" {
        to = [[ $p.port ]]
        [[- if $p.static -]]
        static =  [[ $p.port ]]
        [[- end ]]
      }
      [[ end ]]
    } 
    shutdown_delay = "5s"
      ### Servives
      [[ range $service := .base_app.consul_services ]]
      service {
        name = "[[ or $service.name "${NOMAD_JOB_NAME}"]]"
        port = "[[ $service.port ]]"
        tags = [ [[ range $tag := $service.tags ]] "[[$tag]]", [[end]] ]
        canary_tags = [ [[ range $tag := $service.canary_tags ]] "[[$tag]]", [[end]] ]
        meta {
          prometheus_enable = "true"
          prometheus_path   = "/actuator/prometheus"
        }
        check {
          name     = "ready"
          type     = "http"
          path     = "/actuator/health"
          interval = "10s"
          timeout  = "2s"
        }        
      }
      [[ end ]]     
    task "[[ .base_app.app_name]]" {
      driver = "docker"
      config {
        image = "[[ or (env "DEPLOY_IMAGE") .base_app.image ]]"
        ports = [ [[ range $p := .base_app.ports ]] "[[ $p.name ]]", [[ end ]] ]
        sysctl = {
          "net.core.somaxconn" = "1000"
        }
        extra_hosts = [
          [[ range $host :=  .base_app.extra_hosts ]]"[[$host]]",[[end]]
        ]
        [[- if gt (len .base_app.entrypoint) 0 ]]
        entrypoint = [ [[ range $c := .base_app.entrypoint ]]"[[$c]]",[[end]] ]
        [[ end ]]
        logging {
          type = "journald"
          config {
            env-regex = "NOMAD_*"
          }
        }        
      }
      env {
        JAEGER_AGENT_IP = "${attr.unique.network.ip-address}"
        JAEGER_AGENT_PORT = "6831"
        JAEGER_AGENT_ADDR = "${attr.unique.network.ip-address}:6831"
        [[- range $k, $v := .base_app.environment_variables ]]
        [[ $k ]] = [[ $v | quote ]]
        [[- end ]]
      }
      ### Template
      [[ range $file := .base_app.app_files ]]
        template {
              data = <<EOF
      [[ fileContents $file.src ]]
      EOF
              destination = "local/[[ $file.destination ]]"
              env = [[ $file.env ]]
        }
      [[end]]      

      ### Kill timed-out
      kill_timeout   = "60s"
      shutdown_delay = "15s"
      
      logs {
        max_files     = 2
        max_file_size = 2
      }      
      resources {
        cpu = "[[ or .base_app.resources.cpu 100]]"
        memory = "[[ or .base_app.resources.memory 300]]"
      }
    }
  }
}
