#!/bin/bash


function is.laptop() {
    local chassis_type chassis_types
    chassis_types=("bla" "Laptop" "Portable" "Sub 3")
    chassis_type=$( sudo dmidecode --string chassis-type )
    [[ " ${chassis_types[@]} " =~ " ${chassis_type} " ]]
}

function is.thinkpad() {
    local procfile=/proc/acpi/ibm/driver
    [ -r $procfile ] && grep -q ThinkPad $procfile
}
