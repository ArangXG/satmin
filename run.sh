#!/bin/bash
# ============================================================
#  SatMiner — Ubuntu Auto Setup & Launcher
#  Usage: bash run.sh
# ============================================================

set -e

VENV_DIR="venv"
CONFIG="config.yaml"
MAIN="satoshi_miner.py"

# Warna output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}"
echo "=============================================="
echo "        SatMiner v3.0 — Ubuntu Launcher      "
echo "=============================================="
echo -e "${NC}"

# ── 1. Cek Python 3.10+ ──────────────────────────────────────
echo -e "${YELLOW}[1/5] Mengecek Python...${NC}"
if ! command -v python3 &>/dev/null; then
  echo -e "${RED}✗ Python3 tidak ditemukan. Install dulu:${NC}"
  echo "  sudo apt install python3 python3-pip python3-venv python3-tk -y"
  exit 1
fi

PY_VERSION=$(python3 -c "import sys; print(sys.version_info.minor)")
PY_MAJOR=$(python3 -c "import sys; print(sys.version_info.major)")
if [ "$PY_MAJOR" -lt 3 ] || [ "$PY_VERSION" -lt 10 ]; then
  echo -e "${RED}✗ Butuh Python 3.10+. Versi saat ini: $(python3 --version)${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Python $(python3 --version) OK${NC}"

# ── 2. Install dependensi sistem ─────────────────────────────
echo -e "${YELLOW}[2/5] Mengecek dependensi sistem...${NC}"
MISSING_PKGS=()
for pkg in python3-venv python3-tk build-essential; do
  if ! dpkg -s "$pkg" &>/dev/null 2>&1; then
    MISSING_PKGS+=("$pkg")
  fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
  echo -e "${YELLOW}  → Install: ${MISSING_PKGS[*]}${NC}"
  sudo apt update -qq
  sudo apt install -y "${MISSING_PKGS[@]}"
fi
echo -e "${GREEN}✓ Dependensi sistem OK${NC}"

# ── 3. Setup virtual environment ─────────────────────────────
echo -e "${YELLOW}[3/5] Menyiapkan virtual environment...${NC}"
if [ ! -d "$VENV_DIR" ]; then
  python3 -m venv "$VENV_DIR"
  echo -e "${GREEN}  → venv dibuat${NC}"
else
  echo -e "${GREEN}  → venv sudah ada, dipakai ulang${NC}"
fi

# Aktifkan venv
source "$VENV_DIR/bin/activate"

# ── 4. Install dependensi Python ─────────────────────────────
echo -e "${YELLOW}[4/5] Install dependensi Python...${NC}"
pip install --upgrade pip -q
pip install -r requirements.txt -q
echo -e "${GREEN}✓ Dependensi Python terpasang${NC}"

# ── 4b. Compile ekstensi C (opsional, untuk kecepatan lebih) ─
echo -e "${YELLOW}  → Mencoba compile C extension (keccak_pow)...${NC}"
if python3 setup.py build_ext --inplace &>/dev/null 2>&1; then
  echo -e "${GREEN}  ✓ C extension berhasil dikompile (mode cepat aktif)${NC}"
else
  echo -e "${YELLOW}  ⚠ C extension gagal dikompile, pakai mode Python (masih OK)${NC}"
fi

# ── 5. Cek private key di config.yaml ────────────────────────
echo -e "${YELLOW}[5/5] Mengecek config.yaml...${NC}"
if grep -q "YOUR_PRIVATE_KEY_HERE" "$CONFIG"; then
  echo -e "${RED}"
  echo "  ╔══════════════════════════════════════════╗"
  echo "  ║  ⚠  PRIVATE KEY BELUM DIISI!            ║"
  echo "  ║  Edit config.yaml lalu isi:             ║"
  echo "  ║    private_key: \"0xYOUR_KEY_HERE\"       ║"
  echo "  ╚══════════════════════════════════════════╝"
  echo -e "${NC}"
  read -rp "  Buka config.yaml sekarang untuk diedit? (y/n): " EDIT_NOW
  if [[ "$EDIT_NOW" =~ ^[Yy]$ ]]; then
    "${EDITOR:-nano}" "$CONFIG"
  else
    echo -e "${YELLOW}  Lanjut tanpa private key (pastikan isi sebelum mining)${NC}"
  fi
else
  echo -e "${GREEN}✓ Private key terdeteksi di config.yaml${NC}"
fi

# ── Cek display untuk GUI ─────────────────────────────────────
echo ""
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
  echo -e "${YELLOW}⚠  Tidak ada display terdeteksi (headless/server mode).${NC}"
  echo -e "   GUI tidak bisa jalan. Opsi:"
  echo -e "   • Jalankan di Ubuntu Desktop"
  echo -e "   • Gunakan: ${CYAN}export DISPLAY=:0${NC} jika ada X server"
  echo -e "   • Atau pasang Xvfb: ${CYAN}sudo apt install xvfb && Xvfb :99 -screen 0 1024x768x24 &${NC}"
  echo -e "                        ${CYAN}export DISPLAY=:99${NC}"
  echo ""
fi

# ── Jalankan! ─────────────────────────────────────────────────
echo -e "${CYAN}=============================================="
echo -e "  Menjalankan SatMiner..."
echo -e "==============================================${NC}"
echo ""

python3 "$MAIN"
