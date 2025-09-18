#!/bin/bash

# -------------------------------------------------------------
# Script Agressivo de Reinstalação do Docker (Snap → APT)
# -------------------------------------------------------------
# Funções:
#  - Abort e kill forçado do Snap Docker e containers travados
#  - Remoção completa do Snap Docker mesmo que processos estejam travados
#  - Correção de pacotes quebrados
#  - Reinstalação limpa do Docker via APT
#  - Reestabelecimento garantido do Shellhub mesmo em falhas críticas
#  - Logs detalhados para diagnóstico
# -------------------------------------------------------------
#
# Para execucao via SSH dockerizado, use:
#  chmod +x ./refatoredocker.sh
#  setsid bash -c '/refatoredocker.sh > /refatoredocker.log 2>&1 < /dev/null; reboot' && tail -f /refatoredocker.log
#
# Apos a execucao deste script (para conferir o resultado), use:
#  bash -lc "LC_ALL=C.UTF-8; printf '\n\n'; printf '==================================================================================\n           Informações sobre o Docker presente\n==================================================================================\n'; ( printf 'Componente\tInstalado\tCaminho\tVersao\tFonte\n'; for p in \$(which -a docker 2>/dev/null || true); do ver=\$($p --version 2>/dev/null | sed -n 's/.* version //p' | head -n1); src='Outro'; [[ \$p == /snap/* ]] && src='Snap' || (dpkg -l | grep -qE 'docker.io|docker-ce' && src='APT' || true); printf 'Docker\tSim\t%s\t%s\t%s\n' \"\$p\" \"\${ver:-N/A}\" \"\$src\"; done; [ \$(which -a docker 2>/dev/null | wc -l) -eq 0 ] && printf 'Docker\tNao\t-\t-\t-\n'; if snap list docker >/dev/null 2>&1; then snapver=\$(snap list docker | awk 'NR==2{print \$2}'); printf 'Docker Snap\tSim\t/snap/bin/docker\t%s\tSnap\n' \"\$snapver\"; else printf 'Docker Snap\tNao\t-\t-\t-\n'; fi; if dpkg -l | grep -qE 'docker.io|docker-ce'; then aptpkg=\$(dpkg -l | awk '/docker.io|docker-ce/{print \$2\" \"\$3; exit}'); printf 'Docker APT\tSim\t-\t%s\tAPT\n' \"\$aptpkg\"; else printf 'Docker APT\tNao\t-\t-\t-\n'; fi; compose=\$(command -v docker-compose 2>/dev/null || true); if [ -n \"\$compose\" ]; then compver=\$($compose --version 2>/dev/null | sed -n 's/.*version //p'); printf 'Docker Compose\tSim\t%s\t%s\tStandalone\n' \"\$compose\" \"\${compver:-N/A}\"; else if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then compver=\$(docker compose version 2>/dev/null | sed -n 's/.*version //p' | head -n1); printf 'Docker Compose\tSim\t%s\t%s\tPlugin\n' \"\$(command -v docker)\" \"\${compver:-N/A}\"; else printf 'Docker Compose\tNao\t-\t-\t-\n'; fi; fi; ) | column -t -s\$'\t'; printf '\n==================================================================================\n           Script disponibilizado por: Sr. Victor Bstista - t.me/LevyMac \n==================================================================================\n\n\n';"


echo "[INFO] Use Ctrl+C para interromper"
for i in $(seq 60 -1 1); do
    printf "\rAguardando: %2d segundos antes de iniciar o script..." "$i"
    sleep 1
done

# Verifica se o Snap Docker está instalado
if ! snap list docker >/dev/null 2>&1; then
    echo -e "\n\033[48;5;130;97m  [MENSAGEM] Snap Docker não encontrado.  \033[0m\n\n"
    bash -lc "LC_ALL=C.UTF-8; printf '\n\n'; printf '==================================================================================\n           Informações sobre o Docker presente\n==================================================================================\n'; ( printf 'Componente\tInstalado\tCaminho\tVersao\tFonte\n'; for p in \$(which -a docker 2>/dev/null || true); do ver=\$($p --version 2>/dev/null | sed -n 's/.* version //p' | head -n1); src='Outro'; [[ \$p == /snap/* ]] && src='Snap' || (dpkg -l | grep -qE 'docker.io|docker-ce' && src='APT' || true); printf 'Docker\tSim\t%s\t%s\t%s\n' \"\$p\" \"\${ver:-N/A}\" \"\$src\"; done; [ \$(which -a docker 2>/dev/null | wc -l) -eq 0 ] && printf 'Docker\tNao\t-\t-\t-\n'; if snap list docker >/dev/null 2>&1; then snapver=\$(snap list docker | awk 'NR==2{print \$2}'); printf 'Docker Snap\tSim\t/snap/bin/docker\t%s\tSnap\n' \"\$snapver\"; else printf 'Docker Snap\tNao\t-\t-\t-\n'; fi; if dpkg -l | grep -qE 'docker.io|docker-ce'; then aptpkg=\$(dpkg -l | awk '/docker.io|docker-ce/{print \$2\" \"\$3; exit}'); printf 'Docker APT\tSim\t-\t%s\tAPT\n' \"\$aptpkg\"; else printf 'Docker APT\tNao\t-\t-\t-\n'; fi; compose=\$(command -v docker-compose 2>/dev/null || true); if [ -n \"\$compose\" ]; then compver=\$($compose --version 2>/dev/null | sed -n 's/.*version //p'); printf 'Docker Compose\tSim\t%s\t%s\tStandalone\n' \"\$compose\" \"\${compver:-N/A}\"; else if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then compver=\$(docker compose version 2>/dev/null | sed -n 's/.*version //p' | head -n1); printf 'Docker Compose\tSim\t%s\t%s\tPlugin\n' \"\$(command -v docker)\" \"\${compver:-N/A}\"; else printf 'Docker Compose\tNao\t-\t-\t-\n'; fi; fi; ) | column -t -s\$'\t'; printf '\n==================================================================================\n           Script disponibilizado por: Sr. Victor Bstista - t.me/LevyMac \n==================================================================================\n\n\n';" || true
    exit 1
fi

echo -e "\n\033[44;97m[INFO] Iniciando execução do script... \033[0m\n\n"



set -euo pipefail

# Função de reestabelecimento do Shellhub
reestabelecer_shellhub() {
    echo "\n\033[44;97m[INFO] Reestabelecendo Shellhub... \033[0m"
    docker rm -f $(docker ps -aq 2>/dev/null || true) 2>/dev/null || true
    docker ps || true
    curl -sSf https://cloud.shellhub.io/install.sh | TENANT_ID=<SEU_TOKEN_SHELLHUB> SERVER_ADDRESS=https://cloud.shellhub.io bash || true
    docker update --restart unless-stopped shellhub || true
    echo "\n\033[44;97m[INFO] Shellhub reestabelecido. \033[0m"


    # Reinicia o host de forma segura
    echo "\n\033[44;97m[INFO] Reiniciando o host... \033[0m"
    sleep 5  # pequena pausa para garantir que logs sejam exibidos
    reboot
}

# Garantir execução da função em qualquer falha ou interrupção
trap reestabelecer_shellhub EXIT ERR INT TERM HUP

echo "\n\033[44;97m[INFO] Abortando e finalizando todos processos Snap Docker e containerd travados... \033[0m"
snap abort docker 2>/dev/null || true
pkill -9 -f snapd 2>/dev/null || true
killall -9 docker* containerd* 2>/dev/null || true
snap stop docker 2>/dev/null || true

echo "\n\033[44;97m[INFO] Removendo todos containers Docker Snap (forçado)... \033[0m"
docker ps -aq 2>/dev/null | xargs -r -n1 docker rm -f 2>/dev/null || true

# Repetir remoção para garantir limpeza total
sleep 1
docker ps -aq 2>/dev/null | xargs -r -n1 docker rm -f 2>/dev/null || true

echo "\n\033[44;97m[INFO] Removendo Snap Docker completamente (forçado)... \033[0m"
snap remove --purge --classic docker 2>/dev/null || true
snap remove --purge docker 2>/dev/null || true

echo "\n\033[44;97m[INFO] Corrigindo pacotes quebrados e removendo restos do Docker APT... \033[0m"
dpkg --configure -a || true
apt-get install -f -y || true
apt-get remove -y docker.io docker-compose || true
apt-get autoremove -y || true

echo "\n\033[44;97m[INFO] Instalando Docker via APT... \033[0m"
apt update -y || true
apt install -y --reinstall docker.io docker-compose || true

echo "\n\033[44;97m[INFO] Reiniciando daemon Docker... \033[0m"
systemctl daemon-reload || true
systemctl restart docker || true
sleep 5

bash -lc "LC_ALL=C.UTF-8; printf '\n\n'; printf '==================================================================================\n           Informações sobre o Docker presente\n==================================================================================\n'; ( printf 'Componente\tInstalado\tCaminho\tVersao\tFonte\n'; for p in \$(which -a docker 2>/dev/null || true); do ver=\$($p --version 2>/dev/null | sed -n 's/.* version //p' | head -n1); src='Outro'; [[ \$p == /snap/* ]] && src='Snap' || (dpkg -l | grep -qE 'docker.io|docker-ce' && src='APT' || true); printf 'Docker\tSim\t%s\t%s\t%s\n' \"\$p\" \"\${ver:-N/A}\" \"\$src\"; done; [ \$(which -a docker 2>/dev/null | wc -l) -eq 0 ] && printf 'Docker\tNao\t-\t-\t-\n'; if snap list docker >/dev/null 2>&1; then snapver=\$(snap list docker | awk 'NR==2{print \$2}'); printf 'Docker Snap\tSim\t/snap/bin/docker\t%s\tSnap\n' \"\$snapver\"; else printf 'Docker Snap\tNao\t-\t-\t-\n'; fi; if dpkg -l | grep -qE 'docker.io|docker-ce'; then aptpkg=\$(dpkg -l | awk '/docker.io|docker-ce/{print \$2\" \"\$3; exit}'); printf 'Docker APT\tSim\t-\t%s\tAPT\n' \"\$aptpkg\"; else printf 'Docker APT\tNao\t-\t-\t-\n'; fi; compose=\$(command -v docker-compose 2>/dev/null || true); if [ -n \"\$compose\" ]; then compver=\$($compose --version 2>/dev/null | sed -n 's/.*version //p'); printf 'Docker Compose\tSim\t%s\t%s\tStandalone\n' \"\$compose\" \"\${compver:-N/A}\"; else if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then compver=\$(docker compose version 2>/dev/null | sed -n 's/.*version //p' | head -n1); printf 'Docker Compose\tSim\t%s\t%s\tPlugin\n' \"\$(command -v docker)\" \"\${compver:-N/A}\"; else printf 'Docker Compose\tNao\t-\t-\t-\n'; fi; fi; ) | column -t -s\$'\t'; printf '\n==================================================================================\n           Script disponibilizado por: Sr. Victor Bstista - t.me/LevyMac \n==================================================================================\n\n\n';" || true
sleep 5

# Garantir que Docker está ativo antes de reestabelecer Shellhub
MAX_WAIT=120  # segundos
ELAPSED=0

until systemctl is-active docker >/dev/null 2>&1; do
    echo "[INFO] Aguardando Docker iniciar... ($ELAPSED/$MAX_WAIT segundos) \033[0m"
    sleep 2
    ELAPSED=$((ELAPSED+2))

    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
        echo -e "\n\033[48;5;130;97m[ERRO] Docker não iniciou após 2 minutos. Reiniciando o host.\033[0m\n\n"
        sleep 5
        reboot
    fi
done

echo "\n\033[44;97m[INFO] Docker APT instalado e daemon reiniciado com sucesso. \033[0m"
echo "\n\033[44;97m[INFO] Shellhub será reestabelecido automaticamente via trap ao finalizar o script. \033[0m"






