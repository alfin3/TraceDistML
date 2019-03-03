#!/bin/bash

# also see https://www.terraform.io/docs/providers/external/data_source.html#program

set -e

eval "$(jq -r '@sh "export PATH_TO_PRIV_KEY=\(.path_to_priv_key) USER=\(.user)  HOST=\(.host)"')"

TOKEN_COMMAND=$(ssh -i $PATH_TO_PRIV_KEY -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $USER@$HOST sudo kubeadm token create --print-join-command)

jq -n --arg token_command "$TOKEN_COMMAND" '{"token_command":$token_command}'
