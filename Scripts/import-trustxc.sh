#!/bin/bash
set -e

WDA_ROOT=$(dirname $0)/..
SAUCE="$ML2/build-tools/sauce.py"

if [ "$ML2" == "" ]; then
    echo 'Error: $ML2 environment variable must be set.'
    exit 1
fi

import_file() {
    "$SAUCE" -d TRUST_XC_PRIVATE "$ML2/$1" > "$WDA_ROOT/$2"
}

mkdir -p "$WDA_ROOT/WebDriverAgentLib/TrustXC"
import_file src/agents/iOS/Core/TrustXC.m WebDriverAgentLib/TrustXC/TrustXC.m
import_file src/agents/iOS/Core/TrustXC.h WebDriverAgentLib/TrustXC/TrustXC.h

