#!/bin/bash

function main() {
    local cities=${*:-berlin frankfurtam}

    for city in $cities ; do
        echo "${city^^}"
        finger "${city}@graph.no"
        echo
    done
}
main "${@}"
