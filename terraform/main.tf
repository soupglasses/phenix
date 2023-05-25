terraform {
  cloud {
    organization = "imsofi"
    workspaces {
      name = "phenix"
    }
  }
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.6.0"
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

provider "cloudflare" {
  api_token = data.sops_file.secrets-dns.data["cloudflare_token"]
}

data "cloudflare_zone" "byte_surf" {
  name = "byte.surf"
}

# Hosts

resource "cloudflare_record" "byte_surf-nona_hosts-A" {
  zone_id = data.cloudflare_zone.byte_surf.id
  name    = "nona.hosts"
  type    = "A"
  value   = "89.58.34.244"
}

resource "cloudflare_record" "byte_surf-nona_hosts-SSHFP_1" {
  zone_id = data.cloudflare_zone.byte_surf.id
  name    = "nona.hosts"
  type    = "SSHFP"
  data {
    algorithm   = "1"
    type        = "2"
    fingerprint = "84d768f3a348146aa3ae6c195ae516522731ff2fc0e32bc254ac8e2b08f8078d"
  }
}

resource "cloudflare_record" "byte_surf-nona_hosts-SSHFP_4" {
  zone_id = data.cloudflare_zone.byte_surf.id
  name    = "nona.hosts"
  type    = "SSHFP"
  data {
    algorithm   = "4"
    type        = "2"
    fingerprint = "ea2c60748fafe3d40f35f2ac34e4187601ca042a5f83298422ba12229c3eb87b"
  }
}

# Services

resource "cloudflare_record" "byte_surf-cloud-CNAME" {
  zone_id = data.cloudflare_zone.byte_surf.id
  name    = "cloud"
  type    = "CNAME"
  value   = "nona.hosts.byte.surf."
}

resource "cloudflare_record" "byte_surf-mc-CNAME" {
  zone_id = data.cloudflare_zone.byte_surf.id
  name    = "mc"
  type    = "CNAME"
  value   = "nona.hosts.byte.surf."
}

resource "cloudflare_record" "byte_surf-read-CNAME" {
  zone_id = data.cloudflare_zone.byte_surf.id
  name    = "read"
  type    = "CNAME"
  value   = "nona.hosts.byte.surf."
}

resource "cloudflare_record" "byte_surf-watch-CNAME" {
  zone_id = data.cloudflare_zone.byte_surf.id
  name    = "watch"
  type    = "CNAME"
  value   = "nona.hosts.byte.surf."
}

# Top level

resource "cloudflare_record" "byte_surf--A" {
  zone_id = data.cloudflare_zone.byte_surf.id
  name    = "@"
  type    = "A"
  value   = "89.58.34.244"
}

# TLS hardening

resource "cloudflare_record" "byte_surf--CAA" {
  zone_id = data.cloudflare_zone.byte_surf.id
  name    = "@"
  type    = "CAA"
  data {
    flags = "0"
    tag   = "issue"
    value = "letsencrypt.org"
  }
}

# Email - Sendinblue

resource "cloudflare_record" "byte_surf--TXT_SPF" {
  zone_id = data.cloudflare_zone.byte_surf.id
  name    = "@"
  type    = "TXT"
  value   = "v=spf1 include:spf.sendinblue.com mx -all"
}

resource "cloudflare_record" "byte_surf--TXT_sendinblue_code" {
  zone_id = data.cloudflare_zone.byte_surf.id
  name    = "@"
  type    = "TXT"
  value   = "sendinblue-code:deaab76cc107c5de8cad5f956450eb6b"
}

resource "cloudflare_record" "byte_surf-dmarc-TXT" {
  zone_id = data.cloudflare_zone.byte_surf.id
  name    = "_dmarc"
  type    = "TXT"
  value   = "v=DMARC1; p=reject;"
}

resource "cloudflare_record" "byte_surf-mail_domainkey-TXT" {
  zone_id = data.cloudflare_zone.byte_surf.id
  name    = "mail._domainkey"
  type    = "TXT"
  value   = "k=rsa;p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDeMVIzrCa3T14JsNY0IRv5/2V1/v2itlviLQBwXsa7shBD6TrBkswsFUToPyMRWC9tbR/5ey0nRBH0ZVxp+lsmTxid2Y2z+FApQ6ra2VsXfbJP3HE6wAO0YTVEJt1TmeczhEd2Jiz/fcabIISgXEdSpTYJhb0ct0VJRxcg4c8c7wIDAQAB"
}
