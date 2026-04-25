# ==============================================================================
#  AGENT      : LaTeX Engineer
#  PROJECT    : Molecular Markers — Scientific Paper Workspace
#  PLATFORM   : macOS (Homebrew TeX Live / Texifier)
#  DESCRIPTION: Build system for the multi-agent scientific paper workspace.
#               Handles Python analysis, LaTeX compilation (EN + PT-BR),
#               and cleanup.
#  DEFAULT    : `make` → figures + PDF EN + PDF PT-BR (both versions)
# ==============================================================================

# --- Configuration ---
PROJECT     := molecular_markers
SRC_DIR     := src
MAIN_TEX    := $(SRC_DIR)/main.tex
OUT_DIR     := output/pdf
SCRIPTS_DIR := scripts
VENV        := .venv
PYTHON      := $(shell [ -f $(VENV)/bin/python ] && echo "$(VENV)/bin/python" || echo "python3")

# pdflatex flags — ABS_OUT_DIR is absolute so it works when cd-ing into src/
ABS_OUT_DIR := $(shell pwd)/$(OUT_DIR)
LATEXFLAGS  := -halt-on-error -interaction=nonstopmode -output-directory=$(ABS_OUT_DIR)

# Biber binary
BIBER       := $(shell command -v biber 2>/dev/null)
PDFLATEX    := $(shell command -v pdflatex 2>/dev/null)

.PHONY: all figures pdf pdf-en pdf-pt open check-deps deps clean distclean help

# ==============================================================================
# DEFAULT TARGET — figures + PDF EN + PDF PT-BR
# ==============================================================================
all: check-deps figures pdf-en pdf-pt
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "✓  Build complete!"
	@echo "   EN  → $(OUT_DIR)/main.pdf"
	@echo "   PT  → $(OUT_DIR)/main_pt.pdf"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ==============================================================================
# STEP 1 — STATISTICIAN: Run Python pipeline to generate figures and tables
# ==============================================================================
figures:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "[Statistician] Running analysis pipeline…"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@mkdir -p output/figures output/tables output/data
	$(PYTHON) $(SCRIPTS_DIR)/plot_test.py

# ==============================================================================
# STEP 2a — LaTeX ENGINEER: Compile English version (main.pdf)
# ==============================================================================
pdf-en: $(MAIN_TEX)
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "[LaTeX Engineer] Compiling EN version…"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@mkdir -p $(ABS_OUT_DIR)
	# Pass 1 — generate .aux + bibliography stubs
	cd $(SRC_DIR) && pdflatex $(LATEXFLAGS) main.tex || true
	# Run biber (bibliography)
	@echo "[LaTeX Engineer] Running biber (EN)…"
	@$(BIBER) $(ABS_OUT_DIR)/main || true
	# Pass 2 — resolve citations
	cd $(SRC_DIR) && pdflatex $(LATEXFLAGS) main.tex || true
	# Pass 3 — finalise cross-references
	cd $(SRC_DIR) && pdflatex $(LATEXFLAGS) main.tex
	@echo "[LaTeX Engineer] EN → $(OUT_DIR)/main.pdf ✓"

# Alias: `make pdf` compiles the EN version (backwards compatible)
pdf: pdf-en

# ==============================================================================
# STEP 2b — LEAD SCIENTIST: Compile Portuguese version (main_pt.pdf)
#   Strategy: generate a temporary main_pt.tex inside src/ (so \input{} and
#   \includegraphics{} paths still resolve), compile it, then clean up.
#   Language swap is done via Python to avoid shell-escaping issues.
# ==============================================================================
pdf-pt: $(MAIN_TEX)
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "[Lead Scientist] Compiling PT-BR version…"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@mkdir -p $(ABS_OUT_DIR)
	# Generate main_pt.tex (language-swapped copy inside src/)
	@$(PYTHON) -c "\
import re, pathlib; \
src = pathlib.Path('$(MAIN_TEX)').read_text(); \
src = src.replace(r'\usepackage[english]{babel}', r'\usepackage[brazil]{babel}'); \
src = re.sub(r'\\\\newcommand\{\\\\langversion\}\{en\}', r'\\\\newcommand{\\\\langversion}{pt}', src); \
pathlib.Path('$(SRC_DIR)/main_pt.tex').write_text(src); \
print('[Lead Scientist] main_pt.tex generated')"
	# Pass 1
	cd $(SRC_DIR) && pdflatex $(LATEXFLAGS) main_pt.tex || true
	# Biber (PT)
	@echo "[LaTeX Engineer] Running biber (PT)…"
	@$(BIBER) $(ABS_OUT_DIR)/main_pt || true
	# Pass 2
	cd $(SRC_DIR) && pdflatex $(LATEXFLAGS) main_pt.tex || true
	# Pass 3
	cd $(SRC_DIR) && pdflatex $(LATEXFLAGS) main_pt.tex
	# Clean up temp source (keep only the PDF)
	@rm -f $(SRC_DIR)/main_pt.tex
	@echo "[Lead Scientist] PT-BR → $(OUT_DIR)/main_pt.pdf ✓"

# ==============================================================================
# UTILITY TARGETS
# ==============================================================================

## Open EN PDF (macOS Preview)
open:
	@open $(OUT_DIR)/main.pdf 2>/dev/null || echo "EN PDF not found — run 'make' first."

## Open PT PDF (macOS Preview)
open-pt:
	@open $(OUT_DIR)/main_pt.pdf 2>/dev/null || echo "PT PDF not found — run 'make' first."

## Open both PDFs
open-all:
	@open $(OUT_DIR)/main.pdf $(OUT_DIR)/main_pt.pdf 2>/dev/null || echo "PDFs not found — run 'make' first."

## Check required dependencies
check-deps:
	@echo "Checking dependencies…"
ifndef PDFLATEX
	@echo "  ✗  pdflatex not found. Install: brew install --cask mactex"
	@exit 1
else
	@echo "  ✓  pdflatex: $(PDFLATEX)"
endif
ifndef BIBER
	@echo "  ⚠️   biber not found — bibliography will be skipped"
else
	@echo "  ✓  biber: $(BIBER)"
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

## Remove LaTeX auxiliary files (keep PDFs)
clean:
	@echo "Cleaning LaTeX auxiliary files…"
	@rm -f $(OUT_DIR)/*.aux $(OUT_DIR)/*.log $(OUT_DIR)/*.out \
	       $(OUT_DIR)/*.toc $(OUT_DIR)/*.bbl $(OUT_DIR)/*.bcf \
	       $(OUT_DIR)/*.blg $(OUT_DIR)/*.fls $(OUT_DIR)/*.fdb_latexmk \
	       $(OUT_DIR)/*.run.xml $(OUT_DIR)/*.synctex.gz \
	       $(OUT_DIR)/*.lof $(OUT_DIR)/*.lot
	@rm -f $(SRC_DIR)/main_pt.tex
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
	@echo "  ════════════════════════════════════════"
	@echo ""
	@echo "  make            → Full build: figures + PDF EN + PDF PT-BR"
	@echo "  make figures    → Run Python analysis (Statistician)"
	@echo "  make pdf        → Compile EN version only"
	@echo "  make pdf-en     → Compile EN version only (alias)"
	@echo "  make pdf-pt     → Compile PT-BR version only"
	@echo "  make open       → Open EN PDF (macOS)"
	@echo "  make open-pt    → Open PT-BR PDF (macOS)"
	@echo "  make open-all   → Open both PDFs (macOS)"
	@echo "  make deps       → Install Python dependencies"
	@echo "  make check-deps → Verify all dependencies"
	@echo "  make clean      → Remove LaTeX aux files"
	@echo "  make distclean  → Remove all generated outputs"
	@echo ""
