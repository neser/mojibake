#!/usr/bin/env bash
# Cria cópias com nomes corrigidos de PDFs/XLSX na pasta atual (não recursivo).
# NÃO renomeia originais. 
# Uso:
#   ./corrigir.sh --dry   # simular
#   ./corrigir.sh         # executar

set -euo pipefail
DRY=0
[[ "${1:-}" == "--dry" ]] && DRY=1

timestamp="$(date +%Y%m%d-%H%M%S)"
LOG="copias_corrigidas_${timestamp}.csv"
echo "original,novo,acao,resultado" > "$LOG"

# Gera nome único se já existir
unique() {
  local t="$1"; local b="${t%.*}"; local e="${t##*.}"
  [[ "$e" == "$b" ]] && e="" || e=".$e"
  local i=1; local c="$t"
  while [[ -e "$c" ]]; do c="${b}-${i}${e}"; ((i++)); done
  printf '%s' "$c"
}

# Corrige mojibake pt-BR (regras específicas + limpeza)
fix_name() {
  local s="$1"

  # --- casos compostos ---
  s="${s//€åES/ÇÕES}"
  s="${s//€åes/ções}"
  s="${s//€Å/ÇÕES}"
  s="${s//€ÇO/ÇÃO}"
  s="${s//€ço/ção}"
  s="${s//€Ç/ÇÃ}"
  s="${s//€ç/çã}"

  # --- sequências com 'o' junto (evita 'çãoo') ---
  s="${s//‡Æo/ção}"
  s="${s//‡ÆO/ÇÃO}"
  s="${s//‡ֶo/ção}"
  s="${s//‡ֶO/ÇÃO}"

  # --- palavras inteiras comuns ---
  s="${s//Elei‡Æo/Eleição}"
  s="${s//elei‡Æo/eleição}"

  # --- fallbacks genéricos ---
  s="${s//‡Æ/ção}"
  s="${s//‡ֶ/ção}"
  s="${s//€å/ções}"
  s="${s//€/ç}"
  s="${s//§/º}"
  s="${s//Âº/º}"

  # UTF-8 bagunçado
  s="${s//Ã¡/á}"; s="${s//Ã©/é}"; s="${s//Ã­/í}"
  s="${s//Ã³/ó}"; s="${s//Ãº/ú}"; s="${s//Ã£/ã}"
  s="${s//Ãµ/õ}"; s="${s//Ã§/ç}"; s="${s//Ã/Ç}"
  s="${s//Ã/Á}"; s="${s//Ã‰/É}"; s="${s//ÃÍ/Í}"
  s="${s//Ã“/Ó}"; s="${s//Ãš/Ú}"

  # --- limpeza de duplos ---
  s="${s//çãoo/ção}"
  s="${s//ÇÃOO/ÇÃO}"

  # normaliza extensão para minúsculo
  local root="${s%.*}"; local ext="${s##*.}"
  [[ "$ext" == "$s" ]] && ext="" || ext=".$(echo "$ext" | tr '[:upper:]' '[:lower:]')"
  printf '%s%s' "$root" "$ext"
}

shopt -s nullglob
ARQS=( *.pdf *.PDF *.xlsx *.XLSX )
if ((${#ARQS[@]}==0)); then
  echo "Nenhum PDF/XLSX encontrado na pasta."
  echo "Log: $LOG"
  exit 0
fi

for f in "${ARQS[@]}"; do
  [[ "$f" == "$LOG" || "$f" == "$(basename "$0")" ]] && continue

  novo="$(fix_name "$f")"

  # força extensão correta
  ext_orig="${f##*.}"; ext_orig_lc="$(echo "$ext_orig" | tr '[:upper:]' '[:lower:]')"
  case "$ext_orig_lc" in
    pdf) novo="${novo%.*}.pdf" ;;
    xlsx) novo="${novo%.*}.xlsx" ;;
  esac

  if [[ "$novo" == "$f" ]]; then
    echo "\"$f\",\"\",\"skip\",\"ja_correto\"" >> "$LOG"
    continue
  fi

  alvo="$(unique "$novo")"

  if [[ $DRY -eq 1 ]]; then
    echo "[DRY] $f -> $alvo"
    echo "\"$f\",\"$alvo\",\"dry\",\"noop\"" >> "$LOG"
    continue
  fi

  if ln "$f" "$alvo" 2>/dev/null; then
    echo "\"$f\",\"$alvo\",\"hardlink\",\"ok\"" >> "$LOG"
    echo "[OK] $f -> $alvo (hardlink)"
  elif cp -a "$f" "$alvo"; then
    echo "\"$f\",\"$alvo\",\"copy\",\"ok\"" >> "$LOG"
    echo "[OK] $f -> $alvo (copy)"
  else
    echo "\"$f\",\"$alvo\",\"copy\",\"FAIL\"" >> "$LOG"
    echo "[ERRO] Falha ao copiar $f -> $alvo" >&2
  fi
done

echo "Log: $LOG"
