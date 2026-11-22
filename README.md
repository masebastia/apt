# Repositorio APT de masebastia

Paquetes `.deb` de las aplicaciones de masebastia para Debian 13 y derivadas, con actualizaciones por `apt`.
Alojado en GitHub Pages: <https://masebastia.github.io/apt/>

## Aplicaciones

| Paquete | Descripción |
|---------|-------------|
| [`confusb`](https://github.com/masebastia/confusb) | Información de los dispositivos USB al conectarlos y búsqueda de su controlador y aplicaciones |

## Instalar el repositorio

    sudo install -d -m 0755 /usr/share/keyrings
    sudo curl -fsSL -o /usr/share/keyrings/masebastia-archive-keyring.gpg \
        https://masebastia.github.io/apt/masebastia-archive-keyring.gpg
    sudo tee /etc/apt/sources.list.d/masebastia.sources >/dev/null <<'EOF'
    Types: deb
    URIs: https://masebastia.github.io/apt
    Suites: stable
    Components: main
    Signed-By: /usr/share/keyrings/masebastia-archive-keyring.gpg
    EOF
    sudo apt update
    sudo apt install confusb

Después se actualiza con `sudo apt upgrade` como el resto del sistema.

La clave de firma tiene la huella `2A3D 246B 679C B1FF 91D0 3FCD 0CD8 83ED CF15 66FA`
(`masebastia APT repository`). Compruébala antes de fiarte: `gpg --show-keys /usr/share/keyrings/masebastia-archive-keyring.gpg`.

Para quitarlo: `sudo apt remove confusb && sudo rm /etc/apt/sources.list.d/masebastia.sources /usr/share/keyrings/masebastia-archive-keyring.gpg`.

## Publicar un paquete (mantenimiento)

    ./publicar.sh ruta/al/paquete_1.0-1_all.deb     # añade, regenera los índices, firma, commit y push

Necesita la clave de firma en el llavero (`gpg --list-secret-keys`), `apt-utils` y `git`. La estructura es la de un
repositorio Debian normal: `dists/stable/main/binary-<arq>/Packages` y `pool/main/<inicial>/<paquete>/`.
