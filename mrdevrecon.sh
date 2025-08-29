#!/bin/bash

# === MrDev Recon Script ===
# Tools needed: subfinder, httpx, katana, arjun, nuclei, gf, nmap, zip
# Author: MrDev
# Version: Final

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

echo "======================================"
echo -e "${YELLOW}     MrDev Recon Script${NC}"
echo " (subfinder + httpx + katana + arjun + nuclei + nmap + gf)"
echo "======================================"

# Inputs
read -p "Enter target domain (e.g. example.com): " domain
read -p "Enter Katana crawl depth [1-5] (default=3): " depth
read -p "Enter HTTP status codes for httpx (comma separated, e.g. 200,302,403) [default=200]: " status
read -p "Run nuclei scan on alive hosts? (y/n): " run_nuclei
read -p "Run gf quick checks (xss/redirect/sqli/rce)? (y/n): " run_gf
read -p "Run nmap port scan on alive hosts? (y/n): " run_nmap
if [[ "$run_nmap" == "y" ]]; then
    read -p "Use full port scan (1-65535)? (y/n, default=n): " full_scan
fi

depth=${depth:-3}
status=${status:-200}

# Prepare workspace (unique folder per domain)
mkdir -p "$domain"
cd "$domain" || exit

echo "======================================"
echo "[*] $(timestamp) Recon started for: $domain"
echo " - Katana depth      : $depth"
echo " - httpx match codes : $status"
echo "======================================"

# Step 0: Ensure gf patterns exist
if [[ "$run_gf" == "y" ]]; then
    if [ ! -d "$HOME/.gf" ] || [ -z "$(ls -A $HOME/.gf)" ]; then
        echo "[*] $(timestamp) Installing gf patterns..."
        git clone https://github.com/1ndianl33t/Gf-Patterns ~/gf-patterns > /dev/null 2>&1
        mkdir -p ~/.gf
        cp ~/gf-patterns/*.json ~/.gf/
        echo -e "${GREEN}[+] gf patterns installed to ~/.gf${NC}"
    fi
fi

# Step 1: Subdomain Enumeration
echo "[*] $(timestamp) Running subfinder..."
subfinder -d "$domain" -silent -o subfinder.txt
echo -e "${GREEN}[+] Subdomains found:${NC} $(wc -l < subfinder.txt)"

# Step 2: Live Hosts
echo "[*] $(timestamp) Checking live hosts with httpx..."
cat subfinder.txt | httpx -silent -mc "$status" -o alive.txt
echo -e "${GREEN}[+] Alive hosts:${NC} $(wc -l < alive.txt)"
rm -f subfinder.txt

# Step 3: Katana Crawl
echo "[*] $(timestamp) Crawling with Katana (depth=$depth)..."
katana -list alive.txt -d "$depth" -jc -fx -silent -o crawl_out.txt
echo -e "${GREEN}[+] URLs crawled:${NC} $(wc -l < crawl_out.txt)"

# Step 4: Extract Params
echo "[*] $(timestamp) Extracting URLs with parameters..."
cat crawl_out.txt | grep "=" | sort -u > urls_with_params.txt
echo -e "${GREEN}[+] URLs with params:${NC} $(wc -l < urls_with_params.txt)"

# Step 5: Arjun
echo "[*] $(timestamp) Running Arjun..."
if command -v arjun &> /dev/null; then
    arjun -i urls_with_params.txt -oT arjun_out.txt 2> arjun_errors.log
else
    /root/.local/bin/arjun -i urls_with_params.txt -oT arjun_out.txt 2> arjun_errors.log
fi
echo -e "${GREEN}[+] Arjun results:${NC} arjun_out.txt"
echo -e "${YELLOW}[*] Errors logged to:${NC} arjun_errors.log"

# Step 6: JS files
echo "[*] $(timestamp) Extracting JS files..."
cat crawl_out.txt | grep "\.js" | sort -u > js_files.txt
echo -e "${GREEN}[+] JS files:${NC} $(wc -l < js_files.txt)"

# Step 7: Nuclei
if [[ "$run_nuclei" == "y" ]]; then
    echo "[*] $(timestamp) Running nuclei (default templates)..."
    nuclei -l alive.txt -tags default -o nuclei_out.txt 2> nuclei_errors.log
    echo -e "${GREEN}[+] Nuclei results:${NC} nuclei_out.txt"
    echo -e "${YELLOW}[*] Errors logged to:${NC} nuclei_errors.log"
fi

# Step 8: gf checks
if [[ "$run_gf" == "y" ]]; then
    echo "[*] $(timestamp) Running gf checks..."
    gf xss urls_with_params.txt > xss_candidates.txt
    gf redirect urls_with_params.txt > redirect_candidates.txt
    gf sqli urls_with_params.txt > sqli_candidates.txt
    gf rce urls_with_params.txt > rce_candidates.txt
    echo -e "${GREEN}[+] XSS candidates:${NC} $(wc -l < xss_candidates.txt)"
    echo -e "${GREEN}[+] Redirect candidates:${NC} $(wc -l < redirect_candidates.txt)"
    echo -e "${GREEN}[+] SQLi candidates:${NC} $(wc -l < sqli_candidates.txt)"
    echo -e "${GREEN}[+] RCE candidates:${NC} $(wc -l < rce_candidates.txt)"
fi

# Step 9: Nmap
if [[ "$run_nmap" == "y" ]]; then
    if [[ "$full_scan" == "y" ]]; then
        echo "[*] $(timestamp) Full Nmap scan (1-65535)..."
        nmap -iL alive.txt -T4 -p- -oA nmap_scan > /dev/null 2>&1
    else
        echo "[*] $(timestamp) Nmap scan (important bug bounty ports)..."
        nmap -iL alive.txt -T4 -p 21,22,25,53,80,110,143,389,443,636,1433,1521,3306,5432,27017,8080,8443,8000,8888,3389 -oA nmap_scan > /dev/null 2>&1
    fi
    echo -e "${GREEN}[+] Nmap results:${NC} nmap_scan.nmap/.gnmap/.xml"
fi

# Step 10: Zip
echo "[*] $(timestamp) Zipping results..."
zip -r recon_$domain.zip * > /dev/null 2>&1
echo -e "${GREEN}[+] Zipped report:${NC} recon_$domain.zip"

# Final Report
echo "======================================"
echo -e "${YELLOW}[*] $(timestamp) Recon finished for: $domain${NC}"
echo "======================================"
echo "Results:"
echo " - alive.txt            => Live hosts"
echo " - crawl_out.txt        => Crawled URLs"
echo " - urls_with_params.txt => URLs with parameters"
echo " - arjun_out.txt        => Hidden parameters"
echo " - js_files.txt         => JavaScript files"
[[ "$run_nuclei" == "y" ]] && echo " - nuclei_out.txt       => Nuclei findings"
[[ "$run_gf" == "y" ]] && echo " - xss_candidates.txt   => Potential XSS params"
[[ "$run_gf" == "y" ]] && echo " - redirect_candidates.txt => Potential Redirect params"
[[ "$run_gf" == "y" ]] && echo " - sqli_candidates.txt  => Potential SQLi params"
[[ "$run_gf" == "y" ]] && echo " - rce_candidates.txt   => Potential RCE params"
[[ "$run_nmap" == "y" ]] && echo " - nmap_scan.*          => Nmap port scan results"
echo " - recon_$domain.zip    => All results zipped"
echo "======================================"
