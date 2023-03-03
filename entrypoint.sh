#!/bin/bash

# Obtener las líneas modificadas en el commit
LINES=$(git diff --unified=0 HEAD^ HEAD | grep -E "^@@.*@@.*$" | cut -d' ' -f3- | sed -e 's/\+[0-9]*//g')

# Iterar sobre las líneas modificadas
while read -r LINE; do
    # Obtener el archivo y línea del cambio
    FILE=$(echo "$LINE" | cut -d':' -f1)
    LINE_NUM=$(echo "$LINE" | cut -d':' -f2)

    # Obtener el código afectado por el cambio
    CODE=$(sed -n "${LINE_NUM}p" "$FILE")

    # Detectar el nombre de la función si se modificó el contenido de la función
    if [[ $CODE =~ ^( )*(function)*[[:space:]]+([_a-zA-Z]+[_a-zA-Z0-9]*)[[:space:]]*\(\)[[:space:]]*\{ ]]; then
        FUNCTION_NAME="${BASH_REMATCH[3]}"
    fi

    # Generar la documentación con OpenAI
    DOCUMENTATION=$(curl -s "https://api.openai.com/v1/engines/davinci-codex/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -d "{\"prompt\": \"Generate documentation for: ${CODE}. Respond only with the required documentation\", \"max_tokens\": 1024, \"n\": 1, \"stop\": \"\n\"}" \
        | jq -r '.choices[].text')

    # Agregar la documentación al principio de la función o antes del cambio
    if [[ -n "$FUNCTION_NAME" ]]; then
        # Agregar documentación al principio de la función
        sed -i "/^function ${FUNCTION_NAME}/i# ${DOCUMENTATION}" "$FILE"
    else
        # Agregar documentación antes del cambio
        sed -i "${LINE_NUM}i# ${DOCUMENTATION}" "$FILE"
    fi
done <<< "$LINES"
