# 05 — Email for Your Domain

Email has three different jobs. Treat them separately:

| Job | Example | Recommended solution |
|---|---|---|
| **Mailboxes** (people read and send mail) | you@example.com in Outlook/Gmail/Thunderbird/phone | **Hosted email**: Google Workspace, Microsoft 365, Zoho Mail, Fastmail, Proton, Migadu, Purelymail |
| **Transactional** (app sends sign-up, password-reset and receipt emails) | no-reply@example.com | **Email API**: Amazon SES, Postmark, Resend, Mailgun, SendGrid, Brevo |
| **Bulk/marketing** (newsletters) | news@example.com | ESP: Mailchimp, Brevo, Buttondown, Listmonk + SES, **on a subdomain** |

> **Industry advice: don't self-host mailboxes for a business** unless you have a reason and the
> time. Deliverability (getting into Gmail and Outlook inboxes) depends on IP reputation that new
> VPS IPs usually lack, and many VPS providers **block outbound port 25**. Self-hosting is a great
> *learning* project. The self-hosting section is at the end.

## The DNS records (needed whichever option you pick)

Full annotated example: [`files/email/dns-records.example.txt`](files/email/dns-records.example.txt).

| Record | What it does | Example |
|---|---|---|
| **MX** | where incoming mail for the domain goes | `@ MX 10 mx.provider.com.` |
| **SPF** (TXT) | which servers may send *as* your domain | `@ TXT "v=spf1 include:_spf.provider.com include:amazonses.com -all"` |
| **DKIM** (TXT/CNAME) | cryptographic signature proving mail wasn't forged; the provider gives you the key | `selector1._domainkey CNAME selector1.provider.net.` |
| **DMARC** (TXT) | policy when SPF/DKIM fail, plus reports | `_dmarc TXT "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com; adkim=s; aspf=s"` |
| **PTR** | reverse DNS of the *sending IP* (self-hosted only) | `203.0.113.25 → mail.example.com` |
| **MTA-STS** + **TLS-RPT** | forces TLS for mail sent *to* you, with reports | `_mta-sts TXT "v=STSv1; id=20261018"` + policy file over HTTPS ([`files/email/mta-sts.txt`](files/email/mta-sts.txt)) |
| **BIMI** (optional) | brand logo in inboxes (needs DMARC enforcement, often a VMC certificate) | `default._bimi TXT "v=BIMI1; l=https://..."` |

**Rules that bite people:**
- Only **one** SPF record per name. Merge the `include:` entries, and stay under **10 DNS lookups**.
- **Alignment:** the visible `From:` domain must match the SPF or DKIM domain, or DMARC fails.
- Roll DMARC out gradually: `p=none` (monitor 2–4 weeks with reports) → `p=quarantine` → `p=reject`.
- Gmail, Yahoo and Microsoft (Outlook.com) **require** SPF + DKIM + DMARC with alignment for bulk
  senders (5,000+/day), plus one-click unsubscribe for marketing and a spam rate under 0.3 %.
  Treat these as mandatory for *every* sender.
- Domains that send **no** mail at all: `v=spf1 -all` + `p=reject` DMARC + `MX 0 .` (null MX) to stop spoofing.

## Option 1 — Hosted mailboxes (most common)

1. Sign up with the provider and verify domain ownership (a TXT record).
2. Add the provider's **MX**, **SPF include**, **DKIM** records, and your **DMARC** record.
3. Wait for the provider's checks to go green, then send a test to https://www.mail-tester.com and
   to a Gmail account (Show original → SPF/DKIM/DMARC: PASS).
4. Create mailboxes and aliases (`admin@`, `postmaster@`, `abuse@`, `dmarc@`), and turn on MFA.

## Option 2 — Transactional email from your app (on the VPS)

- Use the provider's **HTTPS API** (port 443, never blocked) or SMTP submission on **587** with
  credentials. Never port 25 from the app.
- Send from a subdomain such as `mail.example.com` / `notify.example.com`, so a reputation problem
  there doesn't hurt your people's mailboxes.
- Add the provider's DKIM/SPF (return-path) records, and handle **bounces and complaints**
  (webhooks), removing bad addresses.
- For server notifications (cron, alerts, unattended-upgrades): `msmtp-mta` relaying through the
  same provider:
  ```bash
  sudo apt install -y msmtp-mta
  # /etc/msmtprc: host smtp.provider.com, port 587, tls on, auth on, user <smtp-user>
  # Password: NOT in the file. Fetch it from the secret manager each time:
  #   passwordeval "bws secret get <secret-id> | jq -r .value"     (bws token available to that user via systemd-creds/keyring)
  echo "test" | mail -s "msmtp works" you@example.com
  ```

## Option 3 — Self-hosting a mail server (learning / special needs)

Requirements before you start:
- A VPS provider that allows (or will unblock) **outbound TCP 25**, and a clean IP
  (check it at https://mxtoolbox.com/blacklists.aspx).
- **PTR** = `mail.example.com`, and the `A` for `mail.example.com` = the same IP (forward-confirmed reverse DNS).
- 4 GB RAM, plus backups of the mail data.

Use an all-in-one, maintained suite rather than wiring Postfix, Dovecot, Rspamd and friends by hand:

| Suite | Notes |
|---|---|
| **Mailcow (dockerized)** | most popular, full-featured (SOGo webmail, Rspamd, ClamAV), heavy |
| **Mailu** | lighter Docker suite |
| **Stalwart** | modern all-in-one server in Rust (SMTP/IMAP/JMAP), single binary, built-in spam filter |
| **docker-mailserver** | config-file driven, no GUI |
| Mail-in-a-Box | an opinionated whole-box installer for one domain |

Ports to open: 25 (SMTP in), 465/587 (submission), 993 (IMAPS), and 443 for webmail/admin. Then:
warm up the IP slowly, register with **Google Postmaster Tools** and **Microsoft SNDS/JMRP**,
watch DMARC reports, and keep an eye on blocklists.

## Verify

```bash
dig +short MX example.com
dig +short TXT example.com | grep spf
dig +short TXT selector1._domainkey.example.com
dig +short TXT _dmarc.example.com
```
Then use mail-tester.com, the MXToolbox SuperTool, the Gmail "Show original" view, and a DMARC
report viewer (Postmark's free DMARC digests, dmarcian, or self-hosted parsedmarc).

## Exercises
1. Set up hosted mail for a test domain and get 10/10 on mail-tester.
2. Make your app send password-reset emails through SES or Postmark via the API from a subdomain,
   with DKIM aligned.
3. Take a parked domain to `p=reject` with a null MX, then try spoofing it to a Gmail address and see it rejected.
