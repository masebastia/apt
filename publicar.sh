#!/usr/bin/env bash
# Publica uno o más paquetes .deb en este repositorio APT (alojado en GitHub Pages) y lo firma.
#
#   ./publicar.sh paquete.deb [otro.deb ...]     añade los paquetes, regenera los índices, firma, commit y push
#   NO_SUBIR=1 ./publicar.sh paquete.deb         lo mismo pero sin hacer commit ni push (para probar)
#
# Necesita: dpkg-dev, apt-utils (apt-ftparchive), gnupg, git, y la clave de firma en el llavero.
set -euo pipefail
cd "$(dirname "$0")"

CLAVE="${CLAVE_APT:-2A3D246B679CB1FF91D03FCD0CD883EDCF1566FA}"
SUITE="stable"
COMP="main"
ARQUITECTURAS="amd64 arm64"

[[ $# -ge 1 ]] || { echo "uso: $0 paquete.deb [otro.deb ...]" >&2; exit 1; }

# 1) Los paquetes van a pool/<componente>/<inicial>/<paquete fuente>/
for deb in "$@"; do
  [[ -f "$deb" ]] || { echo "no existe: $deb" >&2; exit 1; }
  fuente="$(dpkg-deb -f "$deb" Source 2>/dev/null | cut -d' ' -f1 || true)"
  [[ -n "$fuente" ]] || fuente="$(dpkg-deb -f "$deb" Package)"
  inicial="${fuente:0:1}"
  [[ "$fuente" == lib* ]] && inicial="${fuente:0:4}"
  mkdir -p "pool/$COMP/$inicial/$fuente"
  cp -f "$deb" "pool/$COMP/$inicial/$fuente/"
  echo "añadido: $(basename "$deb")"
done

# 2) Índices de paquetes por arquitectura (los paquetes «all» salen en todas)
base="dists/$SUITE"
for arq in $ARQUITECTURAS; do
  dir="$base/$COMP/binary-$arq"
  mkdir -p "$dir"
  apt-ftparchive --arch "$arq" packages pool > "$dir/Packages"
  gzip -9nkf "$dir/Packages"
  xz -9kf "$dir/Packages"
done

# 3) Release firmado (InRelease para apt moderno y Release.gpg para el resto)
rm -f "$base/Release" "$base/InRelease" "$base/Release.gpg"   # que no se incluyan a sí mismos en el Release
tmp="$(mktemp)"
apt-ftparchive \
  -o APT::FTPArchive::Release::Origin="masebastia" \
  -o APT::FTPArchive::Release::Label="masebastia" \
  -o APT::FTPArchive::Release::Suite="$SUITE" \
  -o APT::FTPArchive::Release::Codename="$SUITE" \
  -o APT::FTPArchive::Release::Architectures="$ARQUITECTURAS" \
  -o APT::FTPArchive::Release::Components="$COMP" \
  -o APT::FTPArchive::Release::Description="Aplicaciones de masebastia" \
  release "$base" > "$tmp"
mv "$tmp" "$base/Release"
chmod 644 "$base/Release"
gpg --batch --yes --local-user "$CLAVE" --clearsign -o "$base/InRelease" "$base/Release"
gpg --batch --yes --local-user "$CLAVE" --armor --detach-sign -o "$base/Release.gpg" "$base/Release"
echo "índices regenerados y firmados con ${CLAVE: -16}"

# 4) Subir
if [[ "${NO_SUBIR:-0}" == "1" ]]; then
  echo "(sin subir: NO_SUBIR=1)"
  exit 0
fi
git add -A
git commit -q -m "Publicar: $(for d in "$@"; do basename "$d"; done | paste -sd' ')"
git push -q
echo "publicado"
