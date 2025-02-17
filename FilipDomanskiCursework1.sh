#!/bin/bash

# validation functions used to validate inputs
function validate_int {
    local num="$1"
    if [[ ! "$num" =~ ^[0-9]+$ ]]; then # check if input is a positive integer
        return 1
    fi
    return 0
}

# input data:
# input processes with validation:
while true; do
read -p "provide number of processes: " Processes
if validate_int "$Processes"; then
    break
else
    echo "invalid input. input must be a positive integer"
fi
done

# input resources with validation:
while true; do
read -p "provide number of resources: " Resources
if validate_int "$Resources"; then
    break
else
    echo "invalid input. input must be a positive integer"
fi
done

# input available resources with validation
while true; do
read -p "provide available resources (space-separated): " available_str
available=($available_str)
if [[ ${#available[@]} -eq "$Resources" ]]; then
    break
else
    echo "invalid input. out of bounds"
fi
done


# input data to maximum demand matrix with validation
read -p "provide maximum demand matrix (space-separated): " max_str
max=($max_str)
for ((i = 0; i < Processes; i++)); do
    while true; do
        read -p "Process $i: " row
        if [[ ${#row[@]} -eq "$Resources" ]]; then
        max[i]="${row[@]}"
        break
    else
        echo "invalid input. out of bounds"
        fi
    done
done

# display maximum demand matrix
echo "Maximum Demand Matrix: "
echo -n "PR|"
for ((i = 0; i < Resources; i++)); do echo -n "R$i|"; done
echo ""
for ((j = 0; j < Processes; j++)); do
    echo -n "P$j|"
    for value in ${max[j]}; do
        echo -n " $value|"
    done
echo ""
done

# input data to allocation matrix with validation
read -p "provide allocation matrix (space-separated): " allocation_str
allocation=($allocation_str)
for ((i = 0; i < Processes; i++)); do
    while true; do
        read -p "Process $i: " row
        if [[ ${#row[@]} -eq "$Resources" ]]; then
        allocation[i]="${row[@]}"
        break
    else
        echo "invalid input. out of bounds"
        fi
    done
done


# display allocation matrix
echo "Allocation Matrix: "
echo -n "PR|"
for ((i = 0; i < Resources; i++)); do echo -n "R$i|"; done
echo ""
for ((j = 0; j < Processes; j++)); do
    echo -n "P$j|"
    for value in ${allocation[j]}; do
        echo -n " $value|"
    done
echo""
done

# resource needs with validation
echo "provide needed resources matrix (space-separated): "
declare -a need
for ((i = 0; i < Processes; i++)); do
    while true; do
        read -p "Process $i: " row
        if [[ "${#row[@]}" -eq "$Resources" ]] && validate_row "${row[@]}"; then        
        need[$i]="${row[@]}"
        break
    else
        echo "invalid input. input must be a positive integer"
        fi
    done
done

# display need matrix
echo "Need Matrix"
echo -n "PR|"
for ((i = 0; i < Resources; i++)); do echo -n "R$i|"; done
echo ""
for ((j = 0; j < Processes; j++)); do
    echo -n "P$j|"
    for value in ${need[j]}; do
        echo -n "$value|"
    done
echo ""
done

# Safety Needs section

echo "Safety needs"
function check_safety {
    local work=(${available[@]})
    local finish=()
    for ((i = 0; i < Processes; i++)); do finish[$i]=0; done #tracks if a process can finish
    local safe_sequence=()

    for ((x = 0; x < Processes; x++)); do
        found=false # reset found for each iteration
        for ((i = 0; i < Processes; i++)); do
            if [[ "${finish[$i]}" == 0  ]];  then # If process is not yet finished
                can_allocate=true
                for ((j = 0; j < Resources; j++)); do
                    need_val="${need[$i,$j]}"
                    work_val="${work[$j]}"
                    if [[ "$need_val" > "$work_val" ]]; then
                        can_allocate=false
                        break
                    fi
                done

                if [[ "$can_allocate" == true ]]; then # Allocate resources if possible
                    for ((j = 0; j < Resources; j++)); do
                        work[$j]=$((work[$j] + alloc_p[$i, $j]))
                    done    
                    safe_sequence+=($i)
                    finish[$i]=1
                    found=true
                fi
            fi
        done
        if [[ ! "$found" ]]; then
            echo "unsafe state detected! deadlock possible."
            break
        fi
    done

    if [[ ${#safe_sequence[@]} -eq "$Processes" ]]; then
        echo "System is in safe state. All processes execute properly. Safe sequence: ${safe_sequence[@]}"
        return 0
    else
        echo "unsafe state detected! deadlock possible."
        return 1
    fi
}

# initial safety check
check_safety || exit 1
