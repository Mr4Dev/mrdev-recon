# 🔎 MrDev Recon Script  

Automated recon script for **Bug Bounty Hunters** & **Pentesters**.  
It combines modern tools from ProjectDiscovery & community to perform fast, modular, and effective reconnaissance.  

---

## 🚀 Features
- 🕵️ Subdomain enumeration → [subfinder](https://github.com/projectdiscovery/subfinder)  
- 🌐 Live hosts detection → [httpx](https://github.com/projectdiscovery/httpx)  
- 🕸️ Crawling & JS extraction → [katana](https://github.com/projectdiscovery/katana)  
- 🔑 Hidden parameter discovery → [arjun](https://github.com/s0md3v/Arjun)  
- ⚡ Vulnerability scanning → [nuclei](https://github.com/projectdiscovery/nuclei)  
- 🎯 Quick param checks → [gf](https://github.com/tomnomnom/gf) + [Gf-Patterns](https://github.com/1ndianl33t/Gf-Patterns)  
- 🔒 Port scanning → [nmap](https://nmap.org/)  
- 📦 Results auto-zipped for archiving  

Each target domain gets its own folder → results never mix.  

---

## 📂 Output Structure
For each target, the following files are generated:

- `alive.txt` → Live hosts  
- `crawl_out.txt` → Crawled URLs  
- `urls_with_params.txt` → URLs with parameters  
- `arjun_out.txt` → Hidden parameters (Arjun)  
- `js_files.txt` → Extracted JavaScript files  
- `nuclei_out.txt` → Nuclei findings (optional)  
- `xss_candidates.txt`, `sqli_candidates.txt`, `rce_candidates.txt` → gf checks (optional)  
- `nmap_scan.*` → Nmap results (`.nmap`, `.gnmap`, `.xml`)  
- `recon_<domain>.zip` → All results zipped  

---

## 📦 Requirements
Make sure these tools are installed on your system:

- [subfinder](https://github.com/projectdiscovery/subfinder)  
- [httpx](https://github.com/projectdiscovery/httpx)  
- [katana](https://github.com/projectdiscovery/katana)  
- [arjun](https://github.com/s0md3v/Arjun)  
- [nuclei](https://github.com/projectdiscovery/nuclei)  
- [gf](https://github.com/tomnomnom/gf) + [patterns](https://github.com/1ndianl33t/Gf-Patterns)  
- [nmap](https://nmap.org/)  
- [zip](https://linux.die.net/man/1/zip)  

Install missing dependencies on Debian/Ubuntu:
```bash
sudo apt update
sudo apt install golang-go python3-pip git nmap zip -y
git clone https://github.com/<your-username>/mrdev-recon.git
cd mrdev-recon
chmod +x mrdevrecon.sh

