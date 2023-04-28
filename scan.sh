#!/bin/bash

# Configurações
NETWORK="192.168.0.0/24"
OUTPUT_FILE="output.txt"
HTML_OUTPUT_FILE="output.html"
SCRIPTS_DIRECTORY="/usr/share/nmap/scripts"
SCAN_OPTIONS="-sS -sV -sC --script-args http.useragent='Mozilla/5.0'"
 
# Realiza o scan da rede
echo "Iniciando scan na rede $NETWORK ..."
nmap $SCAN_OPTIONS -oA $OUTPUT_FILE $NETWORK > /dev/null

# Filtra apenas as informações relevantes para a saída
cat $OUTPUT_FILE.gnmap | grep "Status: Up" | awk '{print $2}' > hosts.txt
echo "" > $HTML_OUTPUT_FILE
echo "<html><head><title>Relatório Nmap</title></head><body>" >> $HTML_OUTPUT_FILE
echo "<h1>Relatório Nmap - $NETWORK</h1>" >> $HTML_OUTPUT_FILE

# Itera sobre cada host encontrado na rede
while read host; do
    echo "Analisando host $host ..."
    echo "<h2>Host $host</h2>" >> $HTML_OUTPUT_FILE
    echo "<table><tr><th>Porta</th><th>Estado</th><th>Serviço</th><th>Vulnerabilidades</th></tr>" >> $HTML_OUTPUT_FILE
    
    # Realiza um scan de portas no host
    ports=$(nmap -p- --min-rate=1000 -T4 $host | grep ^[0-9] | cut -d '/' -f 1 | tr '\n' ',' | sed s/,$//)
    
    # Verifica se há serviços rodando em cada porta encontrada
    for port in $(echo $ports | sed "s/,/ /g"); do
        service=$(nmap -p $port -sV $host | grep "open " | awk '{print $3}')
        state=$(nmap -p $port -sV $host | grep "open " | awk '{print $2}')
        vulns=$(nmap -p $port --script vuln $host --script-args unsafe=1 | grep -E '^\|\s+\w+' | sed 's/|\s//' | tr '\n' ',' | sed s/,$//)

        # Formata a saída para cada porta aberta encontrada
        echo "<tr><td>$port</td><td>$state</td><td>$service</td><td>$vulns</td></tr>" >> $HTML_OUTPUT_FILE
    done

    echo "</table><br>" >> $HTML_OUTPUT_FILE
done < hosts.txt

echo "</body></html>" >> $HTML_OUTPUT_FILE

# Remove arquivos temporários
rm $OUTPUT_FILE.* hosts.txt

echo "Scan finalizado. Resultados salvos em $HTML_OUTPUT_FILE"
