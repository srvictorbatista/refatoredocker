# REFATOREDOCKER
## Pensado para ambientes em que não se tem acesso físico ao servidor, e o acesso SSH é controlado (restrito ao docker)
## Se destina a remover docker snap, instalar docker clássico via shellhub ou outro SSH dockerizado. Por isso, sensivel a ausencia do ambioente docker.

Este script nasceu de uma necessidade de instalar o docker clássico a partir de uma **conexão SSH dockerizada (como SHELLHUB)**, mas atende a qualquer demanda onde é necessário sobstituir o Docker Snap (padrão do Ubuntu Server), pelo docker clássico via APT.
Para fins de praticidade e commodidade, este script inclui reinstalação do container SSH e reestabelecimento automatico de conexão SSH via SHELLHUB. Mas pode ser ajustado para reestabelecer quaisquer tipos de conexão onde o serviço SSH é dockerizado. 
Este script foi testado em ambientes Ubuntu 22.04, Ubuntu 25 e usado em produção. Oferecendo segurança no que se propõe com 100% de aproveitamento (até o momento, sem reports negativos). 

## Ao executar este script uma contagem regressiva de 60 segundos é iniciada, antes de realizar as alterações necessárias.

# AVISO:
Se estiver usando ShellHub para executar este script. Não deixe de informar seu token para que a conexão seja retomada. Se não for usar o script na raiz do seridor, adapte a execução.


Para **execução (na raiz)** via SSH dockerizado, use:
``` 
chmod +x ./refatoredocker.sh && setsid bash -c '/refatoredocker.sh > /refatoredocker.log 2>&1 < /dev/null; reboot' && tail -f /refatoredocker.log
```

## FUNÇÕES:
  - Abort e kill forçado do Snap Docker e containers travados
  - Remoção completa do Docker Snap mesmo que processos estejam travados
  - Correção de pacotes quebrados
  - Reinstalação limpa do Docker via APT
  - Reestabelecimento garantido do Shellhub (ou do seu container SSH) mesmo em falhas críticas
  - Logs detalhados para diagnóstico
 -------------------------------------------------------------
Informações adicionais no próprio script.


Ao fim da execução será exibida uma tabela com fnformações detalhadas do docker instalado (Docker Clássico e Docker Compose). Incluindo um arquivo de log ``` refatoredocker.log ``` com detalhes do que foi executado, para consultas.
Caso o Docker Snap não esteja presente. O script informará isto no terminal, não realizando a instalação.

Caso queira reportar alguma falha ou melhoria, será um prazer receber o seu contato.

<a href="https://t.me/LevyMac" target="_blank">t.me/LevyMac</a>
