#!/bin/sh
# Uso:
#   upload.sh list <site> <página>     os arquivos da página e os da _shared do site em JSON (path, size, sha256)
#   upload.sh send <site> <página>     envia cada linha "<caminho> <url>" da entrada; sem rede, sai com 3
#   upload.sh part <arquivo> <offset>  uma parte em base64 e o offset da próxima (ou "end")
# <site> é a pasta do site; <página>, a pasta da página dentro dele (vendas, oferta/vendas, "." na raiz).
# Subpasta com o index.html dela é outra página, e fica de fora.
set -eu

MAX_FILES=300
MAX_FILE_BYTES=$((15 * 1024 * 1024))
MAX_TOTAL_BYTES=$((80 * 1024 * 1024))
PART_BYTES=21000
EXTENSIONS=" html htm css js mjs json webmanifest txt xml svg png jpg jpeg gif webp avif ico woff woff2 ttf otf mp4 webm mp3 pdf "
SHARED=_shared

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

site_and_page() {
  site=${1:-}
  page=${2:-}
  [ -n "$site" ] && [ -n "$page" ] || fail "informe a pasta do site e a da página: sh upload.sh $command <site> <página>"
  [ -d "$site/$page" ] || fail "\"$site/$page\" não é uma pasta"
}

# A subpasta com o index.html dela é outra página do site.
in_other_page() {
  dir=$(dirname "$1")
  while [ "$dir" != "." ]; do
    [ -f "$base/$dir/index.html" ] && return 0
    dir=$(dirname "$dir")
  done
  return 1
}

# Acrescenta ao JSON os arquivos de uma pasta, com os limites de uma página.
add_files() {
  base=$1
  prefix=$2
  role=$3
  paths=$(cd "$base" && find -L . -type f ! -path '*/.*' | sed 's|^\./||' | LC_ALL=C sort)
  count=0
  total=0
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if [ "$role" = page ]; then
      case "/$path" in
        "/$SHARED"/*) [ "$page" = "." ] && continue ;;
      esac
      in_other_page "$path" && continue
      case "/$path/" in
        */"$SHARED"/*) fail "\"$path\": a $SHARED fica na raiz do site, e não dentro da página" ;;
      esac
    fi
    case "$path" in
      *[!A-Za-z0-9._/-]*) fail "caminho com caractere não aceito: \"$prefix$path\" (use letras, números, \"-\", \"_\" e \".\")" ;;
    esac
    ext=$(printf '%s' "${path##*.}" | tr '[:upper:]' '[:lower:]')
    case "$EXTENSIONS" in
      *" $ext "*) ;;
      *) fail "tipo de arquivo não aceito: \"$prefix$path\" (aceitos:$EXTENSIONS)" ;;
    esac
    size=$(size_of "$base/$path")
    [ "$size" -le "$MAX_FILE_BYTES" ] || fail "\"$prefix$path\" tem $size bytes; o limite é 15 MB por arquivo"
    count=$((count + 1))
    total=$((total + size))
    hash=$(sha256_of "$base/$path")
    [ -z "$out" ] || out="$out,"
    out="$out
  {\"path\":\"$prefix$path\",\"size\":$size,\"sha256\":\"$hash\"}"
  done <<EOF
$paths
EOF
  [ "$count" -le "$MAX_FILES" ] || fail "$count arquivos em $base; o limite é $MAX_FILES"
  [ "$total" -le "$MAX_TOTAL_BYTES" ] || fail "$total bytes em $base; o limite é 80 MB"
}

list() {
  site_and_page "$@"
  [ -f "$site/$page/index.html" ] || fail "a página não tem o index.html, que é o que o endereço dela abre"
  out=""
  add_files "$site/$page" "" page
  if [ -d "$site/$SHARED" ]; then
    add_files "$site/$SHARED" "$SHARED/" shared
  fi
  printf '[%s\n]\n' "$out"
}

send() {
  site_and_page "$@"
  sent=0
  while read -r path url || [ -n "${path:-}" ]; do
    [ -n "${path:-}" ] || continue
    [ -n "${url:-}" ] || fail "linha sem o endereço de envio: \"$path\" (use \"<caminho> <url>\")"
    case "$path" in
      "$SHARED"/*) file="$site/$path" ;;
      *) file="$site/$page/$path" ;;
    esac
    [ -f "$file" ] || fail "\"$path\" não está em $file"
    if response=$(curl -sS --fail-with-body --connect-timeout 20 -T "$file" "$url" 2>&1); then
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
  *) fail "uso: sh upload.sh list <site> <página> | send <site> <página> | part <arquivo> <offset>" ;;
esac
