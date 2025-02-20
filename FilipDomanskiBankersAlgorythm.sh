#!/bin/bash

# validation functions used to validate inputs
function validate_int {
    local num="$1"
    if [[ ! "$num" =~ ^[0-9]+$ ]]; then # check if input is a positive integer
        return 1
    fi
    return 0
}

# validation function to validate rows of inputs (space-separated integers)
function validate_row {
    local row=($1)
    for num in "${row[@]}"; do
        if ! validate_int "$num"; then
            return 1
        fi
    done
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
    if [[ ${#available[@]} -eq "$Resources" ]] && validate_row "$available_str"; then
        break
    else
        echo "invalid input. out of bounds or not positive integers"
    fi
done

# input data to maximum demand matrix with validation
echo "provide maximum demand matrix: "
declare -a max
for ((i = 0; i < Processes; i++)); do
    while true; do
        read -p "Process $i: " row_str
        row=($row_str)
        if [[ ${#row[@]} -eq "$Resources" ]] && validate_row "$row_str"; then
            max[i]="${row[@]}"
            break
        else
            echo "invalid input. out of bounds or not positive integers"
        fi
    done
done

# input data to allocation matrix with validation
echo "provide allocation matrix: "
declare -a allocation
for ((i = 0; i < Processes; i++)); do
    while true; do
        read -p "Process $i: " row_str
        row=($row_str)
        if [[ ${#row[@]} -eq "$Resources" ]] && validate_row "$row_str"; then
            allocation[i]="${row[@]}"
            break
        else
            echo "invalid input. out of bounds or not positive integers"
        fi
    done
done

# calculate needs matrix
declare -a needs
for ((i = 0; i < Processes; i++)); do
    for ((j = 0; j < Resources; j++)); do
        max_val=$(echo ${max[$i]} | cut -d ' ' -f $((j+1)))
        alloc_val=$(echo ${allocation[$i]} | cut -d ' ' -f $((j+1)))
        needs[$i]+="$((max_val - alloc_val)) "
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
    echo ""
done

# display needs matrix
echo "Needs Matrix: "
echo -n "PR|"
for ((i = 0; i < Resources; i++)); do echo -n "R$i|"; done
echo ""
for ((j = 0; j < Processes; j++)); do
    echo -n "P$j|"
    for value in ${needs[j]}; do
        echo -n " $value|"
    done
    echo ""
done

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
                    need_val=$(echo ${needs[$i]} | cut -d ' ' -f $((j+1)))
                    work_val="${work[$j]}"
                    if [[ "$need_val" -gt "$work_val" ]]; then
                        can_allocate=false
                        break
                    fi
                done

                if [[ "$can_allocate" == true ]]; then # Allocate resources if possible
                    allocation_row=(${allocation[$i]})
                    for ((j = 0; j < Resources; j++)); do
                        work[$j]=$((work[$j] + allocation_row[$j]))
                    done    
                    safe_sequence+=($i)
                    finish[$i]=1
                    found=true
                    echo "Process $i can be allocated. Updated work: ${work[@]}"
                    echo "Updated Finish: ${finish[@]}"
                fi
            fi
        done
        if [[ ! "$found" ]]; then
            echo "unsafe state detected! deadlock possible."
            break
        fi
    done

    if [[ ${#safe_sequence[@]} -eq "$Processes" ]]; then
        echo "System is in safe state. All processes execute properly. request granted."
        echo "Safe sequence: ${safe_sequence[@]}"
        return 0
    else
        echo "unsafe state detected! deadlock possible. request denied!"
        return 1
    fi
}

# initial safety check
check_safety || exit 1

# Loop to ask if a new process can be added
while true; do
    read -p "Do you want to add a new process? (yes/no): " answer
    if [[ "$answer" == "yes" ]]; then
        Processes=$((Processes + 1))
        while true; do
            read -p "Provide maximum demand for new process (space-separated): " row_str
            row=($row_str)
            if [[ ${#row[@]} -eq "$Resources" ]] && validate_row "$row_str"; then
                max[Processes-1]="${row[@]}"
                break
            else
                echo "invalid input. out of bounds or not positive integers"
            fi
        done

        while true; do
            read -p "Provide allocation for new process (space-separated): " row_str
            row=($row_str)
            if [[ ${#row[@]} -eq "$Resources" ]] && validate_row "$row_str"; then
                allocation[Processes-1]="${row[@]}"
                break
            else
                echo "invalid input. out of bounds or not positive integers"
            fi
        done

        # Update need matrix for the new process
        for (( j = 0; j < Resources; j++ )); do
            max_val=$(echo ${max[$(($Processes-1))]} | cut -d ' ' -f $((j+1)))
            alloc_val=$(echo ${allocation[$(($Processes-1))]} | cut -d ' ' -f $((j+1)))
            needs[$(($Processes-1))]+="$(($max_val - $alloc_val)) "
        done 

        # Run safety check again
        check_safety || exit 1

    
    elif [[ "$answer" == "no" ]]; then
        break
    else
        echo "Please answer yes or no."
    fi
done
