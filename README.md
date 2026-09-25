# DAB - Dispositivo de Autocustodia de Bitcoin

> **AVISO:** O DAB é un dispositivo orientado fundamentalmente para a aprendizaxe no uso e xestión de Bitcoin con autocustodia. Aínda que está deseñado para correr de forma razoablemente segura, a súa utilización con fondos reais (fora da testnet) pode presentar riscos cuxa valoración e aceptación é responsabilidade única do usuario.

![Captura de pantalla do DAB](https://bitnos.info/wp-content/uploads/2026/09/Screenshot_dab.png)

Este script converterá o teu pendrive nun **Dispositivo de Autocustodia de Bitcoin (DAB)**. Fundamentalmente, o script instala Kali Linux Live no dispositivo, crea no espazo libre restante unha partición cifrada con LUKS, e copia nela os arquivos e scripts de configuración para facer de Kali Live unha instalación persistente orientada á xestión de Bitcoin.

## Características

- O sistema operativo execútase desde o pendrive, sen inxerencia do sistema operativo instalado no disco ríxido do computador.
- No seu primeiro uso, o sistema descarga e verifica Electrum da fonte oficial. O sistema incorpora atallos para executar facilmente Electrum en testnet e mainnet.
- Metamask está instalado como unha extensión de Firefox, nun perfil exclusivamente dedicado a isto.
- Permite o enrutamento de todo o tráfico de rede a través de Tor (anonsurf).
- Executa os navegadores Firefox e Chromium en sandbox (firejail). Incorpora Tor Browser preinstalado.
- O portapapeis borrase automaticamente cada 10 segundos.
- O sistema incorpora un cliente de mensaxería XMPP con cifrado E2E (dino-im), para facilitar a comunicación segura con outros usuarios ou dispositivos.

## Descarga

A instalación debe facerse nunha máquina Linux.

1. Descarga o repositorio de maneira que os arquivos `criar-dab.sh` e `criar-dab.sh.sig` estean nun mesmo directorio de nome "DAB".
2. Unha vez feito, descarga a última versión de Kali Linux Live da súa páxina oficial ([https://www.kali.org/get-kali/#kali-live](https://www.kali.org/get-kali/#kali-live)).
3. Graba a imaxe dentro do mesmo directorio DAB no que está o script, renomeando a imaxe como `kali.iso`.

## Verificación

### 1. Verificación da sinatura GPG

O script `criar-dab.sh` está asinado criptograficamente coa chave GPG de `bitnós@bitnos.info` (8CA76965D36D7CEDE52227A28821DDF8FEA87536). Para verificar a súa integridade:

- Descarga a chave pública desde https://keys.openpgp.org/
- Importa a chave con:
```bash
gpg --import 8CA76965D36D7CEDE52227A28821DDF8FEA87536.asc
```
- Cun terminal aberto no directorio no que se encontran `criar-dab.sh` e `criar-dab.sh.sig`, executa:

```bash
gpg --verify criar-dab.sh.sig
```

O resultado debe ser:

```
gpg: assuming signed data in 'criar-dab.sh'
gpg: Signature made Fri Sep 25 12:18:48 2026 CEST
gpg:                using EDDSA key 8CA76965D36D7CEDE52227A28821DDF8FEA87536
gpg: Good signature from "bitnós <bitnos@bitnos.info>" [unknown]
gpg: WARNING: This key is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the owner.
Primary key fingerprint: 8CA7 6965 D36D 7CED E522  27A2 8821 DDF8 FEA8 7536
```

### 2. Verificación automática do hash

O script verifica automaticamente o hash SHA256 da descarga de `persistence.tar.gz`, que é o pacote que contén os principais arquivos e configuracións do DAB.

## Instalación

1. Insire un pendrive de polo menos 16 GB no computador.
   - Para maximizar a velocidade e o rendemento, recoméndase utilizar USB 3.2.
   - O computador no que se utilice o DAB debería ter polo menos 8 GB de RAM.
2. Executa desde o directorio DAB:

```bash
chmod +x criar-dab.sh
./criar-dab.sh
```

> O proceso pode demorar bastante tempo dependendo da velocidade da túa conexión a Internet e da velocidade de escritura da interface USB dos teus dispositivos. Segue os pasos, e ten paciencia!

## Primeiro uso

- O usuario por defecto do sistema e o seu contrasinal son `kali/kali`.
- A primeira vez que se arranque, e regularmente, o sistema debe ser actualizado con:

```bash
sudo apt update
sudo apt upgrade -y
sudo apt autoremove
```

- Cando houbere unha actualización de Electrum, esta poderá ser descargada utilizando o script de Instalar/Actualizar Electrum.
- O Tor Browser actualízase desde a propia aplicación.

## Uso en mainnet

Aínda que xestionar criptomoedas con este dispositivo é moito máis seguro que facelo nun computador convencional (moitísimo máis que en calquera Windows, por exemplo), o DAB está orientado fundamentalmente para o ensino e a aprendizaxe. A súa utilización con fondos reais (fora da testnet) pode presentar riscos cuxa valoración e aceptación é responsabilidade única do usuario.

O uso con fondos reais esixe extremar as precaucións, e significativamente:

- Non instalar novas aplicacións no dispositivo.
- Non navegar por webs maliciosas, especialmente co navegador que ten instalada a extensión MetaMask.

## Dúvidas, suxestións e contacto

Visita [https://bitnos.info](https://bitnos.info) para máis información.
