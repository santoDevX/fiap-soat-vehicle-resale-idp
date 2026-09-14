# Versao 26.7 conforme voce esta usando. Troque a tag se atualizar.
FROM quay.io/keycloak/keycloak:26.7

# Coloca o realm no diretorio que o Keycloak varre automaticamente
# quando recebe a flag --import-realm (confirmado em keycloak.org/server/containers)
COPY realm-export.json /opt/keycloak/data/import/

# start-dev (nao start) e a decisao central deste repo:
# - nao exige hostname, TLS nem proxy headers configurados
# - usa banco H2 embutido, sem RDS
# A propria doc do Keycloak diz que start-dev nao e recomendado para producao real.
# Aceito aqui porque e demonstracao pontual (o video do trabalho), nao um sistema
# em operacao continua. Documentado tambem no ADR deste repositorio.
ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start-dev", "--import-realm"]