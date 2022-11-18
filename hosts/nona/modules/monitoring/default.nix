{...}: {
  imports = [
    ./grafana.nix
    ./prometheus.nix
    ./loki.nix
    ./promtail.nix
  ];
}
