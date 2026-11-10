#!/bin/sh
# Uso:
#   upload.sh list <pasta>             os arquivos da página em JSON (path, size, sha256)
#   upload.sh send <pasta> < linhas    envia cada linha "<caminho> <url>"; sem rede, sai com 3
#   upload.sh part <arquivo> <offset>  uma parte em base64 e o offset da próxima (ou "end")
set -eu

MAX_FILES=300
MAX_FILE_BYTES=$((15 * 1024 * 1024))
MAX_TOTAL_BYTES=$((80 * 1024 * 1024))
PART_BYTES=21000
EXTENSIONS=" html htm css js mjs json webmanifest txt xml svg png jpg jpeg gif webp avif ico woff woff2 ttf otf mp4 webm mp3 pdf "

fail() {
  echo "erro: $*" >&2
  exit 1
}

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | cut -d' ' -f1
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 -r "$1" | cut -d' ' -f1
  else
    fail "sem sha256sum, shasum ou openssl para calcular o sha256"
  fi
}

size_of() {
  wc -c <"$1" | tr -d ' '
}

list() {
  dir=${1:-}
  [ -n "$dir" ] && [ -d "$dir" ] || fail "informe a pasta da página: sh upload.sh list <pasta>"
  [ -f "$dir/index.html" ] || fail "a pasta não tem o index.html, que é o que o endereço da página abre"

  paths=$(cd "$dir" && find -L . -type f ! -path '*/.*' | sed 's|^\./||' | LC_ALL=C sort)
  count=0
  total=0
  out=""
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    case "$path" in
      *[!A-Za-z0-9._/-]*) fail "caminho com caractere não aceito: \"$path\" (use letras, números, \"-\", \"_\" e \".\")" ;;
    esac
    ext=$(printf '%s' "${path##*.}" | tr '[:upper:]' '[:lower:]')
    case "$EXTENSIONS" in
      *" $ext "*) ;;
      *) fail "tipo de arquivo não aceito: \"$path\" (aceitos:$EXTENSIONS)" ;;
    esac
    size=$(size_of "$dir/$path")
    [ "$size" -le "$MAX_FILE_BYTES" ] || fail "\"$path\" tem $size bytes; o limite é 15 MB por arquivo"
    count=$((count + 1))
    total=$((total + size))
    hash=$(sha256_of "$dir/$path")
    [ -z "$out" ] || out="$out,"
    out="$out
  {\"path\":\"$path\",\"size\":$size,\"sha256\":\"$hash\"}"
  done <<EOF
$paths
EOF
  [ "$count" -le "$MAX_FILES" ] || fail "$count arquivos; o limite é $MAX_FILES por página"
  [ "$total" -le "$MAX_TOTAL_BYTES" ] || fail "$total bytes no total; o limite é 80 MB por página"
  printf '[%s\n]\n' "$out"
}

send() {
  dir=${1:-}
  [ -n "$dir" ] && [ -d "$dir" ] || fail "informe a pasta da página: sh upload.sh send <pasta>"
  sent=0
  while read -r path url || [ -n "${path:-}" ]; do
    [ -n "${path:-}" ] || continue
    [ -n "${url:-}" ] || fail "linha sem o endereço de envio: \"$path\" (use \"<caminho> <url>\")"
    [ -f "$dir/$path" ] || fail "\"$path\" não está na pasta"
    if response=$(curl -sS --fail-with-body --connect-timeout 20 -T "$dir/$path" "$url" 2>&1); then
      sent=$((sent + 1))
      echo "enviado: $path"
    else
      status=$?
      case "$status" in
        5 | 6 | 7 | 28 | 35 | 52 | 55 | 56 | 60)
          echo "sem rede para o endereço de envio (curl $status): envie \"$path\" pelo upload_page_file_part" >&2
          exit 3
          ;;
      esac
      fail "\"$path\" não foi enviado: $response"
    fi
  done
  [ "$sent" -gt 0 ] || fail "nenhuma linha \"<caminho> <url>\" na entrada"
  echo "$sent arquivo(s) enviado(s)"
}

part() {
  file=${1:-}
  offset=${2:-0}
  [ -f "$file" ] || fail "informe o arquivo: sh upload.sh part <arquivo> <offset>"
  size=$(size_of "$file")
  [ "$offset" -lt "$size" ] || fail "o offset $offset passa do fim do arquivo ($size bytes)"
  tail -c +$((offset + 1)) "$file" | head -c "$PART_BYTES" | base64 | tr -d '\n'
  echo
  next=$((offset + PART_BYTES))
  if [ "$next" -ge "$size" ]; then echo "end"; else echo "$next"; fi
}

command=${1:-}
[ $# -gt 0 ] && shift
case "$command" in
  list) list "$@" ;;
  send) send "$@" ;;
  part) part "$@" ;;
  *) fail "uso: sh upload.sh list <pasta> | send <pasta> | part <arquivo> <offset>" ;;
esac
