terraform {
  required_providers {
    desec = {
      source  = "Valodim/desec"
      version = "0.3.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.2"
    }
  }
}

provider "sops" {}

data "sops_file" "secrets-dns" {
  source_file = "../secrets/dns.yaml"
}

provider "desec" {
  api_token = data.sops_file.secrets-dns.data["desec_token"]
}

# Hosts

resource "desec_rrset" "byte_surf-nona_hosts-A" {
  domain  = "byte.surf"
  subname = "nona.hosts"
  type    = "A"
  records = ["89.58.34.244"]
  ttl     = 3600
}

# Services

resource "desec_rrset" "byte_surf-cloud-CNAME" {
  domain  = "byte.surf"
  subname = "cloud"
  type    = "CNAME"
  records = ["nona.hosts.byte.surf."]
  ttl     = 3600
}

resource "desec_rrset" "byte_surf-mc-CNAME" {
  domain  = "byte.surf"
  subname = "mc"
  type    = "CNAME"
  records = ["nona.hosts.byte.surf."]
  ttl     = 3600
}

resource "desec_rrset" "byte_surf-read-CNAME" {
  domain  = "byte.surf"
  subname = "read"
  type    = "CNAME"
  records = ["nona.hosts.byte.surf."]
  ttl     = 3600
}

resource "desec_rrset" "byte_surf-watch-CNAME" {
  domain  = "byte.surf"
  subname = "watch"
  type    = "CNAME"
  records = ["nona.hosts.byte.surf."]
  ttl     = 3600
}

# Top level

resource "desec_rrset" "byte_surf--A" {
  domain  = "byte.surf"
  subname = ""
  type    = "A"
  records = ["89.58.34.244"]
  ttl     = 3600
}

# TLS hardening

resource "desec_rrset" "byte_surf--CAA" {
  domain  = "byte.surf"
  subname = ""
  type    = "CAA"
  records = ["0 issue letsencrypt.org"]
  ttl     = 3600
}

# Email hardening

resource "desec_rrset" "byte_surf--TXT" {
  domain  = "byte.surf"
  subname = ""
  type    = "TXT"
  records = ["v=spf1 -all"]
  ttl     = 3600
}

resource "desec_rrset" "byte_surf-dmarc-TXT" {
  domain  = "byte.surf"
  subname = "_dmarc"
  type    = "TXT"
  records = ["v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s;"]
  ttl     = 3600
}

resource "desec_rrset" "byte_surf-domainkey-TXT" {
  domain  = "byte.surf"
  subname = "*._domainkey"
  type    = "TXT"
  records = ["v=DKIM1; p="]
  ttl     = 3600
}
