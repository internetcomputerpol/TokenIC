declare -A identities
identity_list=($(dfx identity list | awk '{print $1}' | tail -n +2))


token_symbol=$(dfx canister call bkyz2-fmaaa-aaaaa-qaaaq-cai icrc1_symbol '()' | tr -d '()"')

for identity in "${identity_list[@]}"; do

    dfx identity use "$identity" &>/dev/null
    principal=$(dfx identity get-principal)
    identities["$identity"]="$principal"
done

echo "---------------------------------------------------------------"
echo "Saldo tokenów dla Identity 🧮"
echo "              "

for identity in "${!identities[@]}"; do
    dfx identity use "$identity" &>/dev/null
    princ=$(dfx identity get-principal)
    balance=$(dfx canister call bkyz2-fmaaa-aaaaa-qaaaq-cai icrc1_balance_of "(record { owner = principal \"$princ\"; })" | tr -d '()"' 2>/dev/null)
    
    
    balance=$(echo "$balance" | sed 's/ nat//g' | sed 's/_//g')
    
    if [ -z "$balance" ]; then
        balance="Błąd: Nie można pobrać salda"
    fi
    
    echo "Identity: $identity"
    echo "Principal ID: $princ"
    echo "Saldo: $balance $token_symbol"
    echo "---------------------------------------------------------------"
done
