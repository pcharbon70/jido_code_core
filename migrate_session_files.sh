#!/bin/bash
# Script to migrate session files from JidoCode to JidoCodeCore

SOURCE_DIR="/home/ducky/code/agentjido/jido_code/lib/jido_code"
TARGET_DIR="/home/ducky/code/agentjido/jido_code_core/lib/jido_code_core"

# Migrate a single file with namespace updates
migrate_file() {
    local src="$1"
    local dst="$2"
    
    # Replace JidoCode with JidoCodeCore in file content
    sed 's/JidoCode\.Session/JidoCodeCore.Session/g' \
        | sed 's/JidoCode\.Agents/JidoCodeCore.Agents/g' \
        | sed 's/JidoCode\.Settings/JidoCodeCore.Settings/g' \
        | sed 's/JidoCode\.Language/JidoCodeCore.Language/g' \
        | sed 's/JidoCode\.PubSubTopics/JidoCodeCore.PubSubTopics/g' \
        | sed 's/JidoCode\.SessionRegistry/JidoCodeCore.SessionRegistry/g' \
        | sed 's/JidoCode\.SessionProcessRegistry/JidoCodeCore.SessionProcessRegistry/g' \
        | sed 's/alias JidoCode\./alias JidoCodeCore./g' \
        | sed 's/@registry JidoCode\.SessionProcessRegistry/@registry JidoCodeCore.SessionProcessRegistry/g' \
        | sed 's/JidoCode\.Livebook/JidoCodeCore.Livebook/g' \
        | sed 's/JidoCode\.PubSubHelpers/JidoCodeCore.PubSubHelpers/g' \
        | sed 's/JidoCode\.Error/JidoCodeCore.Error/g' > "$dst"
}

echo "Migration script ready"
