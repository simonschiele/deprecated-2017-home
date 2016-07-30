#!/bin/bash

function is.laptop() {
    local chassis_type chassis_types
    chassis_types=( "Laptop" "Notebook" "Portable" "Sub Notebook" )
    chassis_type=$( sudo dmidecode --string chassis-type )
    [[ "${chassis_types[@]}" =~ ${chassis_type} ]]
}

function is.thinkpad() {
    grep -iq ThinkPad /proc/acpi/ibm/driver 2>/dev/null
}
