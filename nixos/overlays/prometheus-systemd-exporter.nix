final: prev: {
  prometheus-systemd-exporter = prev.prometheus-systemd-exporter.overrideAttrs (_p: {
    patches = [
      # https://github.com/prometheus-community/systemd_exporter/pull/74
      (final.fetchpatch {
        url = "https://github.com/prometheus-community/systemd_exporter/commit/0afc9bee009740825239df1e6ffa1713a57a5692.patch";
        sha256 = "sha256-ClrV9ZOlRruYXaeQwhWc9h88LP3Rm33Jf/dvxbqRS2I=";
      })
      (final.fetchpatch {
        url = "https://github.com/prometheus-community/systemd_exporter/commit/47d7e92ec34303a8da471fd1c26106f606e5a150.patch";
        sha256 = "sha256-Ox9IE8LeYBflitelyZr4Ih1zSt9ggjnogj6k0qI2kx4=";
      })
    ];
  });
}
