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

resource "desec_rrset" "byte_surf-nona_hosts-SSHFP" {
  domain  = "byte.surf"
  subname = "nona.hosts"
  type    = "SSHFP"
  records = [
    "4 2 ea2c60748fafe3d40f35f2ac34e4187601ca042a5f83298422ba12229c3eb87b",
    "1 2 84d768f3a348146aa3ae6c195ae516522731ff2fc0e32bc254ac8e2b08f8078d"
  ]
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
  records = ["0 issue \"letsencrypt.org\""]
  ttl     = 3600
}

# Email - Sendinblue

resource "desec_rrset" "byte_surf--TXT" {
  domain  = "byte.surf"
  subname = ""
  type    = "TXT"
  records = [
    "v=spf1 include:spf.sendinblue.com mx -all",
    "sendinblue-code:deaab76cc107c5de8cad5f956450eb6b"
  ]
  ttl     = 3600
}

resource "desec_rrset" "byte_surf-dmarc-TXT" {
  domain  = "byte.surf"
  subname = "_dmarc"
  type    = "TXT"
  records = ["v=DMARC1; p=reject;"]
  ttl     = 3600
}

resource "desec_rrset" "byte_surf-mail_domainkey-TXT" {
  domain  = "byte.surf"
  subname = "mail._domainkey"
  type    = "TXT"
  records = ["k=rsa;p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDeMVIzrCa3T14JsNY0IRv5/2V1/v2itlviLQBwXsa7shBD6TrBkswsFUToPyMRWC9tbR/5ey0nRBH0ZVxp+lsmTxid2Y2z+FApQ6ra2VsXfbJP3HE6wAO0YTVEJt1TmeczhEd2Jiz/fcabIISgXEdSpTYJhb0ct0VJRxcg4c8c7wIDAQAB"]
  ttl     = 3600
}
