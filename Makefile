# ==============================================================================
#  AGENT      : LaTeX Engineer
#  PROJECT    : Molecular Markers — Scientific Paper Workspace
#  PLATFORM   : macOS (Homebrew TeX Live / Texifier)
#  DESCRIPTION: Build system for the multi-agent scientific paper workspace.
#               Handles Python analysis, LaTeX compilation, and cleanup.
# ==============================================================================

# --- Configuration ---
PROJECT     := molecular_markers
SRC_DIR     := src
MAIN_TEX    := $(SRC_DIR)/main.tex
OUT_DIR     := output/pdf
SCRIPTS_DIR := scripts
VENV        := .venv
PYTHON      := $(shell [ -f $(VENV)/bin/python ] && echo "$(VENV)/bin/python" || echo "python3")

# pdflatex flags  (OUT_DIR must be absolute so it works when cd-ing into src/)
ABS_OUT_DIR := $(shell pwd)/$(OUT_DIR)
LATEXFLAGS  := -halt-on-error -interaction=nonstopmode -output-directory=$(ABS_OUT_DIR)

# Biber flags (bibliography)
BIBERFLAGS  :=

# Detect if pdflatex is available; fallback message otherwise
PDFLATEX    := $(shell command -v pdflatex 2>/dev/null)
BIBER       := $(shell command -v biber 2>/dev/null)

.PHONY: all figures pdf clean distclean help deps check-deps

# ==============================================================================
# DEFAULT TARGET
# ==============================================================================
all: check-deps figures pdf
	@echo ""
	@echo "✓  Build complete → $(OUT_DIR)/main.pdf"

# ==============================================================================
# STEP 1 — STATISTICIAN: Run Python pipeline to generate figures and tables
# ==============================================================================
figures:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "[Statistician] Running analysis pipeline…"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	$(PYTHON) $(SCRIPTS_DIR)/plot_test.py

# ==============================================================================
# STEP 2 — LaTeX ENGINEER: Compile LaTeX document
# ==============================================================================
pdf: $(MAIN_TEX)
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "[LaTeX Engineer] Compiling document…"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@mkdir -p $(ABS_OUT_DIR)
	# Compile from src/ so that \input{modules/...} and relative paths resolve correctly
	# Pass 1: generate .aux and bibliography stubs
	cd $(SRC_DIR) && pdflatex $(LATEXFLAGS) main.tex || true
ifdef BIBER
	# Run biber for bibliography (uses absolute path to .bcf)
	@echo "[LaTeX Engineer] Running biber…"
	biber $(ABS_OUT_DIR)/main $(BIBERFLAGS) || true
else
	@echo "[LaTeX Engineer] biber not found — skipping bibliography (install: brew install biber)"
endif
	# Pass 2: resolve citations
	cd $(SRC_DIR) && pdflatex $(LATEXFLAGS) main.tex || true
	# Pass 3: finalise cross-references
	cd $(SRC_DIR) && pdflatex $(LATEXFLAGS) main.tex
	@echo ""
	@echo "[LaTeX Engineer] PDF output → $(OUT_DIR)/main.pdf"

# Compile EN version (default)
pdf-en: MAIN_TEX := $(SRC_DIR)/main.tex
pdf-en: pdf

# Compile PT version: swap language in a temp file
pdf-pt:
	@echo "[Lead Scientist] Switching to Portuguese…"
	# Create a temporary PT main.tex inside src/ so module paths still resolve
	@sed 's/usepackage\[english\]{babel}/usepackage[brazil]{babel}/; \
	      s/newcommand{\\langversion}{en}/newcommand{\\langversion}{pt}/' \
	      $(SRC_DIR)/main.tex > $(SRC_DIR)/main_pt_tmp.tex
	@cd $(SRC_DIR) && pdflatex $(LATEXFLAGS) main_pt_tmp.tex || true
	@biber $(ABS_OUT_DIR)/main_pt_tmp || true
	@cd $(SRC_DIR) && pdflatex $(LATEXFLAGS) main_pt_tmp.tex || true
	@cd $(SRC_DIR) && pdflatex $(LATEXFLAGS) main_pt_tmp.tex
	@mv $(ABS_OUT_DIR)/main_pt_tmp.pdf $(ABS_OUT_DIR)/main_pt.pdf
	@rm -f $(ABS_OUT_DIR)/main_pt_tmp.* $(SRC_DIR)/main_pt_tmp.tex
	@echo "[Lead Scientist] PT version → $(OUT_DIR)/main_pt.pdf"

# ==============================================================================
# UTILITY TARGETS
# ==============================================================================

## Open the compiled PDF (macOS)
open:
	@open $(OUT_DIR)/main.pdf 2>/dev/null || echo "PDF not found — run 'make' first."

## Check required dependencies
check-deps:
	@echo "Checking dependencies…"
ifndef PDFLATEX
	@echo "  ✗  pdflatex not found. Install via: brew install --cask mactex"
	@exit 1
else
	@echo "  ✓  pdflatex: $(PDFLATEX)"
endif
	@$(PYTHON) -c "import pandas; import matplotlib; import numpy" 2>/dev/null && \
	    echo "  ✓  Python packages OK" || \
	    (echo "  ✗  Missing Python packages. Run: make deps" && exit 1)

## Create virtual environment and install Python dependencies
deps:
	@if [ ! -d "$(VENV)" ]; then \
	    echo "Creating virtual environment in $(VENV)/..."; \
	    python3 -m venv $(VENV); \
	fi
	$(VENV)/bin/pip install --quiet -r requirements.txt
	@echo "✓  Dependencies installed in $(VENV)/"

## Remove LaTeX auxiliary files
clean:
	@echo "Cleaning LaTeX auxiliary files…"
	@rm -f $(OUT_DIR)/*.aux $(OUT_DIR)/*.log $(OUT_DIR)/*.out \
	       $(OUT_DIR)/*.toc $(OUT_DIR)/*.bbl $(OUT_DIR)/*.bcf \
	       $(OUT_DIR)/*.blg $(OUT_DIR)/*.fls $(OUT_DIR)/*.fdb_latexmk \
	       $(OUT_DIR)/*.run.xml $(OUT_DIR)/*.synctex.gz
	@echo "Done."

## Remove ALL generated outputs (figures, tables, PDFs)
distclean: clean
	@echo "Removing generated outputs…"
	@rm -f output/figures/*.pdf output/tables/*.tex output/data/*.csv
	@rm -f $(OUT_DIR)/main.pdf $(OUT_DIR)/main_pt.pdf
	@echo "Done."

## Show available targets
help:
	@echo ""
	@echo "  Molecular Markers Paper — Build System"
	@echo "  ═══════════════════════════════════════"
	@echo ""
	@echo "  make            → Full build (figures + PDF, English)"
	@echo "  make figures    → Run Python analysis (Statistician)"
	@echo "  make pdf        → Compile LaTeX only (LaTeX Engineer)"
	@echo "  make pdf-pt     → Compile Portuguese version"
	@echo "  make open       → Open compiled PDF (macOS)"
	@echo "  make deps       → Install Python dependencies"
	@echo "  make check-deps → Verify all dependencies"
	@echo "  make clean      → Remove LaTeX aux files"
	@echo "  make distclean  → Remove all generated outputs"
	@echo ""
