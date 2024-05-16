job "[[ template "job_name" . ]]" {
  region      = "[[ var "region" . ]]"
  datacenters = [ [[ range $idx, $dc := (var "datacenters" .) ]][[if $idx]],[[end]][[ $dc | quote ]][[ end ]] ]
  type = "service"
  [[ range $c := (var "constraints" .) ]]
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
    count = [[or (var "count" .) 1]]
    update {
      auto_revert = [[ or (var "auto_revert" .) true ]]
      auto_promote = [[ or (var "auto_promote" .) false ]]
      max_parallel = [[ or (var "max_parallel" .) 1 ]]
      canary     = [[ orvar "(." .canary) 0 ]]
      min_healthy_time = "[[ or (var "min_healthy_time" .) "10s" ]]"
      healthy_deadline = "[[ or (var "healthy_deadline" .) "3m" ]]"
      progress_deadline = "[[ or (var "progress_deadline" .) "10m" ]]"
      stagger = "[[ or (var "stagger" .) "30s" ]]"
    }
    migrate {
      max_parallel     = [[ or (var "migrate.max_parallel" .) 1 ]]
      health_check     = "[[ or (var "migrate.health_check" .) "checks" ]]"
      min_healthy_time = "[[ or (var "migrate.min_healthy_time" .) "10s" ]]"
      healthy_deadline = "[[ or (var "migrate.healthy_deadline" .) "5m" ]]"
    }    
    network {
      [[ range $p := (var "ports" .) -]]
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
      [[ range $service := (var "consul_services" .) ]]
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
    task "[[ (var "app_name" .)]]" {
      driver = "docker"
      config {
        image = "[[ or (env "DEPLOY_IMAGE") (var "image" .) ]]"
        ports = [ [[ range $p := (var "ports" .) ]] "[[ $p.name ]]", [[ end ]] ]
        sysctl = {
          "net.core.somaxconn" = "1000"
        }
        extra_hosts = [
          [[ range $host :=  (var "extra_hosts" .) ]]"[[$host]]",[[end]]
        ]
        [[- if gt (len (var "entrypoint" .)) 0 ]]
        entrypoint = [ [[ range $c := (var "entrypoint" .) ]]"[[$c]]",[[end]] ]
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
        [[- range $k, $v := (var "environment_variables" .) ]]
        [[ $k ]] = [[ $v | quote ]]
        [[- end ]]
      }
      ### Template
      [[ range $file := (var "app_files" .) ]]
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
        cpu = "[[ or (var "resources.cpu" .) 100]]"
        memory = "[[ or (var "resources.memory" .) 300]]"
      }
    }
  }
}
