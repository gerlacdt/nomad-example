job "consul" {
  datacenters = ["dc1"]
  type = "system"
  update {
    stagger = "5s"
    max_parallel = 1

  }

  group "consul-agent" {
    task "consul-agent" {
      driver = "exec"
      config {
        command = "start.sh"
        args = []
      }

      artifact {
        source = "https://github.com/gerlacdt/nomad-example/raw/master/consul_linux64/consul.zip"
      }

      resources {
        cpu = 500
        memory = 128
        network {
          mbits = 1

          port "server" {
            static = 8300

          }
          port "serf_lan" {
            static = 8301

          }
          port "serf_wan" {
            static = 8302

          }
          port "rpc" {
            static = 8400

          }
          port "http" {
            static = 8500

          }
          port "dns" {
            static = 8600

          }
        }
      }
    }
  }
}
