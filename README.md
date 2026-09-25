# DAB

AVISO: O DAB é un dispositivo orientado fundamentalmente para a aprendizaxe no uso e xestion de Bitcoin con autocustodia. Ainda que está deseñado para correr de forma razonabelmente segura, a súa utilización con fondos reais (fora da testnet) pode apresentar riscos cuxa valoración e aceptación é responsabilidade única do usuario. 

Este repositorio disponibiliza un conxunto de instruccións, scripts e arquivos de configuración para converter un pendrive nun Dispositivo de Autocustodia de Bitcoin. 

- O sistema operativo execútase desde o pen-drive, sen inxerencia do sistema operativo instalado no disco ríxido do computador.
- No seu primeiro uso, o sistema descarga e verifica Electrum da fonte oficial. O sistema incorpora atallos para executar facilmente Electrum en testnet e mainnet.
- O sistema 
- Incorpora un cliente de mensaxería xmpp con cifrado e2e (dino-im), para facilitar a comunicación segura con outros usuarios ou dispositivos.
- Permite o enrutamento de todo o tráfico de rede a través de Tor (anonsurf)
- Executa os navgadores Firefox e Chromium en sandbox (firejail). Incorpora Tor Browser preinstalado.
- O portapapeis borrase automaticamente cada 10 segundos.

  # Verificación

  O script criar-dab.sh está asinado criptograficamente coa chave GPG de bitnós (8CA76965D36D7CEDE52227A28821DDF8FEA87536). 
