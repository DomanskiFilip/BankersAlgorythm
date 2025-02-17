#!/bin/bash

# validation functions used to validate inputs
function validate_int {
  local num="$1"
  if [[ ! "$num" =~ ^[0-9]+$ ]]; then # check if input is a positive integer
    return 1 # return 1 if not a positive integer
  fi
  return 0 # return 0 if it is a positive integer
}

# input data:
# input processes with validation:

while true; do
  read -p "Provide number of processes: " Processes
  if validate_int "$Processes"; then
    break
  else
    echo "Invalid input. Input must be a positive integer"
  fi
done

# input resources with validation:
while true; do
  read -p "Provide number of resources: " Resources
  if validate_int "$Resources"; then
    break
  else
    echo "Invalid input. Input must be a positive integer"
  fi
done

# input available resources with validation
while true; do
  read -p "Provide available resources (space-separated): " available_str
  available=($available_str)

  if [[ ${#available[@]} -eq "$Resources" ]]; then
    break
  else
    echo "Invalid input. Out of bounds"
  fi
done

# input data to maximum demand matrix with validation
echo "Provide maximum demand matrix (space-separated): "
max=() # Initialize max as an empty array
for ((i=0; i < Processes; i++)); do
  while true; do
    read -p "Process $i: " row_str
    row=($row_str)

    if [[ ${#row[@]} -eq "$Resources" ]]; then
      max+=("(${row[@]})") # Append row as a tuple to max
      break
    else
      echo "Invalid input. Out of bounds"
    fi
  done
done

# display maximum demand matrix
echo "Maximum Demand Matrix:"

echo -n "  " # Add space for alignment
for ((i=0; i < Resources; i++)); do
  echo -n "R$i "
done
echo

for ((j = 0; j < Processes; j++)); do
  echo -n "P$j "
  # Access the tuple and print its elements
  for value in "${max[j]}"; do
    # Remove parentheses and print the value
    value="${value//[()]/}"
    echo -n "$value "
  done
  echo
done

# input data to allocation matrix with validation
read -p "Provide allocation matrix (space-separated): " allocation_str
allocation=($allocation_str)

for ((i=0; i < Processes; i++)); do
  while true; do
    read -p "Process $i: " row_str
    row=($row_str)

    if [[ ${#row[@]} -eq "$Resources" ]]; then
      allocation+=("(${row[@]})") # Append row as a tuple to allocation
      break
    else
      echo "Invalid input. Out of bounds"
    fi
  done
done

# display allocation matrix
echo "Allocation Matrix:"

echo -n "  " # Add space for alignment
for ((i=0; i < Resources; i++)); do
  echo -n "R$i "
done
echo

for ((j = 0; j < Processes; j++)); do
  echo -n "P$j "
  # Access the tuple and print its elements
  for value in "${allocation[j]}"; do
    # Remove parentheses and print the value
    value="${value//[()]/}"
    echo -n "$value "
  done
  echo
done

# resource needs with validation
echo "Provide needed resources matrix (space-separated):"

declare -a need # Declare 'need' as an array

for ((i=0; i < Processes; i++)); do
  while true; do
    read -p "Process $i: " row_str
    row=($row_str)

    if [[ ${#row[@]} -eq "$Resources" ]]; then
      need+=("(${row[@]})") # Append row as a tuple to need
      break
    else
      echo "Invalid Input. Input must be a positive integer"
    fi
  done
done

# display need matrix
echo "Need Matrix"

echo -n "  " # Add space for alignment
for ((i=0; i < Resources; i++)); do
  echo -n "R$i "
done
echo

for ((j = 0; j < Processes; j++)); do
  echo -n "P$j "
  # Access the tuple and print its elements
  for value in "${need[j]}"; do
    # Remove parentheses and print the value
    value="${value//[()]/}"
    echo -n "$value "
  done
  echo
done

# Safety Needs section
echo "Safety needs"
function check_safety {
  local work=(${available[@]})
  local finish=()

  for ((i = 0; i < Processes; i++)); do 
    finish[$i]=0 # Initialize finish array with 0 (not finished)
  done

  local safe_sequence=()

  for ((x = 0; x < Processes; x++)); do
    local found=false # Reset found for each iteration

    for ((i = 0; i < Processes; i++)); do
      if [[ "${finish[$i]}" == "0" ]]; then # If process is not yet finished
        local can_allocate=true

        for ((j = 0; j < Resources; j++)); do
          need_val=$(echo "${need[$i]}" | cut -d' ' -f$((j+1)) | tr -d '()') # Extract value from tuple
          work_val="${work[$j]}"

          if [[ "$need_val" > "$work_val" ]]; then
            can_allocate=false
            break
          fi
        done

        if [[ "$can_allocate" == true ]]; then # Allocate resources if possible
          found=true
          finish[$i]=1 # Mark process as finished
          safe_sequence+=("P$i")

          # Update work: work = work + allocation_i
          for ((j = 0; j < Resources; j++)); do
            alloc_val=$(echo "${allocation[$i]}" | cut -d' ' -f$((j+1)) | tr -d '()') # Extract value from tuple
            work[$j]=$((work[$j] + alloc_val))
          done
          break # Go to the next process
        fi
      fi
    done

    if [[ "$found" == false ]]; then
      echo "System is in an unsafe state."
      return 1 # Indicate unsafe state
    fi
  done

  echo "System is in a safe state."
  echo "Safe sequence: ${safe_sequence[@]}"
  return 0 # Indicate safe state
}

check_safety