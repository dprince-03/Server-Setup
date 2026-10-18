# 03 — Domain Names and DNS

## How it fits together

```
You buy example.com at a REGISTRAR  →  the registrar points the domain at NAMESERVERS (DNS host)
                                         →  the DNS host serves RECORDS (A, AAAA, MX, TXT...)
                                              →  browsers/mail servers look them up
```
The registrar and the DNS host can be different companies (e.g. register at Porkbun/Namecheap/
Cloudflare Registrar, host DNS at Cloudflare/deSEC/your provider/Route 53).

**Secure the registrar account:** MFA, registrar lock, auto-renew, and a recovery email that is
**not** on the same domain (if the domain expires, you lose that email too).

## Record types you'll use

| Type | Purpose | Example |
|---|---|---|
| **A** | name → IPv4 | `@ A 203.0.113.10` |
| **AAAA** | name → IPv6 | `@ AAAA 2001:db8::10` |
| **CNAME** | alias to another name (not at the apex) | `www CNAME example.com.` |
| **MX** | mail servers for the domain | `@ MX 10 mx1.mailprovider.com.` |
| **TXT** | verification, SPF, DKIM, DMARC | `@ TXT "v=spf1 include:... -all"` |
| **CAA** | which CAs may issue certificates | `@ CAA 0 issue "letsencrypt.org"` |
| **SRV** | service location (some protocols) | `_imaps._tcp SRV 0 1 993 mail.example.com.` |
| **NS** | delegation (subdomain to another DNS host) | `lab NS ns1.other.com.` |
| **PTR** | reverse DNS: IP → name (set at the **VPS provider**, not your DNS host) | `203.0.113.10 → mail.example.com` |

A full working zone is in [`files/dns/zone.example.txt`](files/dns/zone.example.txt).

## Connect a domain to a VPS (step by step)

1. At the DNS host, create `A @ → <VPS IPv4>`, `AAAA @ → <VPS IPv6>`, and `CNAME www → example.com.`
   (or more A/AAAA records for subdomains: `app`, `api`...).
2. TTL: use **300 s** while you're setting up or migrating, and raise it to 3600 s once stable.
3. Check propagation:
   ```bash
   dig +short example.com A
   dig +short example.com AAAA
   dig @1.1.1.1 +short www.example.com
   dig NS example.com +short
   ```
4. Set **reverse DNS (PTR)** for the VPS IP to your hostname in the provider panel.
5. Add a **CAA** record restricting issuance to the CA you use.
6. Now get TLS certificates (chapter 04). The ACME HTTP challenge needs the A/AAAA records to
   already point at the server.

## Cloudflare proxy (orange cloud): pros and cons

- Pros: hides your origin IP, DDoS protection, a CDN cache, a WAF, free TLS at the edge.
- Cons: Cloudflare terminates your TLS; non-HTTP ports aren't proxied (SSH/mail must use
  **grey-cloud** DNS-only records); and you need **Full (strict)** SSL mode with a valid origin
  certificate.
- If you proxy, firewall the origin so 80/443 accept traffic **only from Cloudflare IP ranges**
  (or use Cloudflare Tunnel and open **no** inbound ports at all).

## DNSSEC

Enable it at the DNS host, then add the DS record at the registrar (automatic when they're the
same company). It protects against forged DNS answers. Turn it off *before* moving DNS hosts.

## Exercises
1. Point `app.example.com` at your VPS with A + AAAA, and confirm with `dig` from two resolvers.
2. Move a test domain's DNS from the registrar to Cloudflare with zero downtime: copy the records
   first, then switch nameservers.
3. Set the PTR record and verify it: `dig -x 203.0.113.10 +short`.
