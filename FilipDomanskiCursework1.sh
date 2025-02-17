#!/bin/bash

# Function to validate input as a positive integer
validate_int() {
  local num="$1"
  if [[ ! "$num" =~ ^[0-9]+$ ]]; then
    return 1  # Failure
  fi
  return 0  # Success
}
# --- Get the number of processes and resources ---
while true; do
  read -p "Enter the number of processes: " Processes
  if validate_int "$Processes"; then
    break
  else
    echo "Invalid input. Number of processes must be a positive integer."
  fi
done

while true; do
  read -p "Enter the number of resources: " Resources
  if validate_int "$Resources"; then
    break
  else
    echo "Invalid input. Number of resources must be a positive integer."
  fi
done


# --- Available Resources ---
while true; do
  read -p "Provide available resources (space-separated): " available_str
  available=($available_str)

  if [[ ${#available[@]} -eq "$Resources" ]]; then
    break
  else
    echo "Invalid input. You must provide $Resources values (positive integers)."
  fi
done


# --- Maximum Demand Matrix ---
max=()
echo "Provide Maximum Demand Matrix (space-separated):"
for ((i = 0; i < Processes; i++)); do
  while true; do
    read -p "Process $i: " row_str
    row=($row_str)
    if [[ ${#row[@]} -eq "$Resources" ]]; then
      max[i]=("${row[@]}")
      break
    else
      echo "Invalid input. You must provide $Resources values (positive integers)."
    fi
  done
done

echo "Maximum Demand Matrix:"
echo -n "PR "
for ((i = 0; i < Resources; i++)); do echo -n "R$i "; done; echo ""
for ((j = 0; j < Processes; j++)); do
  echo -n "P$j "
  for value in "${max[j][@]}"; do echo -n "$value "; done; echo ""
done


# --- Allocation Matrix ---
allocation=()
echo "Provide Allocation Matrix (space-separated):"
for ((i = 0; i < Processes; i++)); do
  while true; do
    read -p "Process $i: " row_str
    row=($row_str)
    if [[ ${#row[@]} -eq "$Resources" ]]; then
      allocation[i]=("${row[@]}")
      break
    else
      echo "Invalid input. You must provide $Resources values (positive integers)."
    fi
  done
done

echo "Allocation Matrix:"
echo -n "PR "
for ((i = 0; i < Resources; i++)); do echo -n "R$i "; done; echo ""
for ((j = 0; j < Processes; j++)); do
  echo -n "P$j "
  for value in "${allocation[j][@]}"; do echo -n "$value "; done; echo ""
done


# --- Need Matrix ---
need=()
echo "Provide Needed Resources Matrix (space-separated):"
for ((i = 0; i < Processes; i++)); do
  while true; do
    read -p "Process $i: " row_str
    row=($row_str)
    if [[ ${#row[@]} -eq "$Resources" ]]; then
      need[i]=("${row[@]}")
      break
    else
      echo "Invalid input. You must provide $Resources values (positive integers)."
    fi
  done
done

echo "Need Matrix:"
echo -n "PR "
for ((i = 0; i < Resources; i++)); do echo -n "R$i "; done; echo ""
for ((j = 0; j < Processes; j++)); do
  echo -n "P$j "
  for value in "${need[j][@]}"; do echo -n "$value "; done; echo ""
done

# ... (rest of your Banker's Algorithm code) ...

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