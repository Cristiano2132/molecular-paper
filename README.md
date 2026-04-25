# 📄 Molecular Paper — Marcadores Moleculares (SNP/SSR)

> Workspace de escrita científica multi-agente para caracterização de marcadores moleculares.

---

## 🧬 Sobre o Projeto

Este repositório contém um pipeline completo e reprodutível para a redação e análise de artigos científicos sobre **marcadores moleculares (SNP/SSR)**. O projeto é estruturado como um **sistema multi-agente** que separa as responsabilidades de análise, redação, compilação LaTeX e revisão bibliográfica em agentes especializados.

### Funcionalidades

- **Pipeline Python reprodutível** — análise estatística de PIC, He, Ho com seed fixo
- **LaTeX modular** — artigo com toggle PT-BR / EN via variável `\langversion`
- **Sistema multi-agente** — 7 agentes especializados com skills e workflows
- **Build automatizado** — `make` executa figuras + compilação LaTeX completa
- **Scripts de validação** — sincronia EN/PT, consistência de citações, QC de dados

---

## 🚀 Início Rápido

### Pré-requisitos

- Python 3.10+
- TeX Live 2022+ (com `pdflatex` e `biber`)
- macOS (testado com TeX Live 2026)

```bash
# 1. Criar ambiente virtual e instalar dependências Python
make deps

# 2. Gerar figuras e tabelas (pipeline Statistician)
make figures

# 3. Compilar o PDF
make pdf

# 4. Tudo de uma vez
make
```

### Abrir o PDF

```bash
make open   # Abre output/pdf/main.pdf no Preview (macOS)
```

---

## 📁 Estrutura do Projeto

```
molecular_paper/
├── .agent/                  # Sistema multi-agente
│   ├── ARCHITECTURE.md      # Mapa do sistema
│   ├── agents/              # 7 agentes especializados
│   ├── skills/              # 6 skills de domínio
│   ├── workflows/           # 7 slash commands (/analyze, /compile, …)
│   └── scripts/             # Scripts de validação
├── data/
│   ├── raw/                 # Dados brutos (não modificar!)
│   └── processed/           # Dados pós-QC (gerados por scripts)
├── output/
│   ├── figures/             # Figuras PDF vetoriais (geradas por `make figures`)
│   ├── tables/              # Tabelas LaTeX (geradas por `make figures`)
│   ├── data/                # CSVs de reprodutibilidade
│   └── pdf/                 # PDF compilado (gerado por `make pdf`)
├── references/
│   └── references.bib       # Base bibliográfica BibLaTeX
├── scripts/
│   └── plot_test.py         # Pipeline do Statistician (PIC, He, Ho)
├── src/
│   ├── main.tex             # Entry-point LaTeX (Lead Scientist)
│   └── modules/             # Módulos por seção (EN e PT-BR)
├── Makefile                 # Orquestrador central
├── requirements.txt         # Dependências Python
└── config.yaml              # Configuração do workspace
```

---

## 🤖 Sistema Multi-Agente

| Agente | Responsabilidade |
|--------|-----------------|
| `lead-scientist` | Orquestra o artigo, gerencia idiomas EN/PT |
| `statistician` | Pipeline Python (PIC, He, Ho, Fst) |
| `geneticist` | Interpreta resultados, redige Discussion |
| `latex-engineer` | Compila o PDF, resolve erros LaTeX |
| `literature-reviewer` | Gerencia `references.bib` |
| `data-curator` | QC dos dados genotípicos |
| `paper-orchestrator` | Coordena múltiplos agentes |

### Workflows disponíveis (`/slash commands`)

| Comando | Ação |
|---------|------|
| `/analyze` | Roda pipeline estatístico completo |
| `/compile` | Compila o PDF (LaTeX Engineer) |
| `/sync-lang` | Sincroniza módulos PT-BR ↔ EN |
| `/write-section` | Redige ou atualiza uma seção |
| `/review-lit` | Busca e incorpora referências |
| `/validate-data` | QC completo dos dados |
| `/submit-check` | Checklist de pré-submissão |

---

## 🔬 Estatísticas Calculadas

- **PIC** — Polymorphism Information Content (Botstein et al., 1980)
- **He** — Expected Heterozygosity (gene diversity)
- **Ho** — Observed Heterozygosity
- **Fis** — Inbreeding Coefficient

---

## 📚 Journals Alvo

- Genetics and Molecular Biology (GMB)
- Crop Breeding and Applied Biotechnology (CBAB)
- Molecular Plant Breeding (MPB)

---

## 🧪 Validação

```bash
# Verificar sincronia EN ↔ PT-BR
.venv/bin/python .agent/scripts/check_lang_sync.py

# Verificar consistência de citações
.venv/bin/python .agent/scripts/check_citations.py

# Health check do LaTeX
bash .agent/scripts/check_latex.sh
```

---

## 📋 Make Targets

```bash
make              # Build completo (figures + PDF EN)
make figures      # Apenas pipeline Python
make pdf          # Apenas compilação LaTeX
make pdf-pt       # Versão PT-BR
make open         # Abrir PDF (macOS)
make deps         # Instalar dependências Python
make check-deps   # Verificar dependências
make clean        # Remover auxiliares LaTeX
make distclean    # Remover todos os outputs
make help         # Listar todos os targets
```

---

## 📄 Licença

Este projeto está em desenvolvimento. Todos os direitos reservados.
