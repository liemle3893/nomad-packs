#!/bin/sh
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
PACKS_DIR=$SCRIPT_DIR/packs
PACK_NAME=$1
PACK_DIR=$PACKS_DIR/$PACK_NAME

if [ -z "$PACK_NAME" ]; then
	echo "Usage: $0 <pack_name>"
	exit 1
fi

if [ -d "$PACK_DIR" ]; then
	echo "Directory $PACK_NAME already exists"
	exit 1
fi

init_pack() {
	mkdir -p $PACK_DIR
	mkdir -p $PACK_DIR/templates
	touch $PACK_DIR/README.MD
	touch $PACK_DIR/metadata.hcl
	touch $PACK_DIR/variables.hcl
	touch $PACK_DIR/CHANGELOG.md
	touch $PACK_DIR/outputs.tpl
}

init_metadata() {
	cat <<EOF >$PACK_DIR/metadata.hcl
app {
  url = "https://github.com/mikenomitch/hello_world_server"
  author = "Mike Nomitch"
}

pack {
  name = "hello_world"
  description = "This pack contains a single job that renders hello world, or a different greeting, to the screen."
  url = "https://github.com/hashicorp/nomad-pack-community-registry/hello_world"
  version = "0.3.2"
}

EOF
}

init_variables() {
	cat <<EOF >$PACK_DIR/variables.hcl
variable "datacenters" {
  description = "A list of datacenters in the region which are eligible for task placement."
  type        = list(string)
  default     = ["dc1"]
}

variable "region" {
  description = "The region where the job should be placed."
  type        = string
  default     = "global"
}

variable "app_count" {
  description = "The number of apps to be deployed"
  type        = number
  default     = 3
}

variable "resources" {
  description = "The resource to assign to the application."
  type = object({
    cpu    = number
    memory = number
  })
  default = {
    cpu    = 500,
    memory = 256
  }
}

EOF
}

init_outputs() {
	cat <<EOF >$PACK_DIR/outputs.tpl
Congrats on deploying [[ .nomad_pack.pack.name ]].

There are [[ .hello_world.app_count ]] instances of your job now running on Nomad.

EOF
}

init_templates() {
	cat <<EOF >$PACK_DIR/templates/job.nomad.tpl
job "hello_world" {
  region      = "[[ .hello_world.region ]]"
  datacenters = [ [[ range $idx, $dc := .hello_world.datacenters ]][[if $idx]],[[end]][[ $dc | quote ]][[ end ]] ]
  type = "service"

  group "app" {
    count = [[ .hello_world.count ]]

    network {
      port "http" {
        static = 80
      }
    }

    [[/* this is a go template comment */]]

    task "server" {
      driver = "docker"
      config {
        image = "mikenomitch/hello-world"
        network_mode = "host"
        ports = ["http"]
      }

      resources {
        cpu    = [[ .hello_world.resources.cpu ]]
        memory = [[ .hello_world.resources.memory ]]
      }
    }
  }
}	
EOF
}

init_pack
init_metadata
init_variables
init_templates
init_outputs
