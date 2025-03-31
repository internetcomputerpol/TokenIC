#!/bin/bash

echo -e "\033[1;36m
████████  ██████  ██   ██ ███████ ███    ██ ██  ██████ 
   ██    ██    ██ ██  ██  ██      ████   ██ ██ ██      
   ██    ██    ██ █████   █████   ██ ██  ██ ██ ██      
   ██    ██    ██ ██  ██  ██      ██  ██ ██ ██ ██      
   ██     ██████  ██   ██ ███████ ██   ████ ██  ██████ 
                                                       
\033[0m"
echo -e "\033[1;36m== Skrypt automatyzujący tworzenie Tokenów na ICP ==\033[0m"
echo -e "\033[1;36mv1.0\033[0m"
echo ""

if pgrep -x "dfx" > /dev/null
then
    echo "dfx jest uruchomiony ✅"
else
    echo "Uruchamianie dfx...🎚"
    dfx start --clean --background
fi

echo -e "\033[1;36m1️⃣  Tworzenie Canistra icrc1_ledger_canister... ⛽️\033[0m"
echo "---------------------------------------------------------------";
echo '1) Wybierz Motoko'
echo '2) Wybierz Frontend ( albo bez None)'
echo '3) Jeżeli potrzebujesz wybierz II [KLIKNIJ ENTER]'
echo "---------------------------------------------------------------";
dfx new icrc1_ledger_canister
cd icrc1_ledger_canister


cat > dfx.json <<EOF
{
  "canisters": {
    "icrc1_ledger_canister": {
      "type": "custom",
      "candid": "https://raw.githubusercontent.com/dfinity/ic/d87954601e4b22972899e9957e800406a0a6b929/rs/rosetta-api/icrc1/ledger/ledger.did",
      "wasm": "https://download.dfinity.systems/ic/d87954601e4b22972899e9957e800406a0a6b929/canisters/ic-icrc1-ledger.wasm.gz"
    }
  },
  "defaults": {
    "build": {
      "args": "",
      "packtool": ""
    }
  },
  "output_env_file": ".env",
  "version": 1
}
EOF

clear

echo -e "\033[1;36m2️⃣  Sprawdzam dostępne identity...🔎\033[0m"
echo '4) Wybierz Minter Identity konto mintujące token ⛏'
echo "---------------------------------------------------------------"

# Pobierz listę istniejących identity
identity_list=$(dfx identity list | awk '{print $1}' | tail -n +2)
options=("nowe" $identity_list)

echo "Wybierz identity ( dla Mintera  wpisując liczbę np.  2, 3 , 4 itp"
echo "Za liczbami masz odpowiadajace im identity"
echo "Wpisz 1 aby stworzyć nowe identity"
echo "po wpisaniu zatwierdź klikając [ENTER]"
echo "---------------------------------------------------------------"

select selected_identity in "${options[@]}"; do
    if [ -z "$selected_identity" ]; then
        echo "Niepoprawny wybór, spróbuj ponownie."
        continue
    fi

    if [ "$selected_identity" == "nowe" ]; then
        echo "Podaj nazwę identity:"
        read selected_identity

        # Sprawdź czy identity istnieje
        if dfx identity list | grep -q "^$selected_identity$"; then
            echo "Identity istnieje, używam utworzonego: $selected_identity"
            dfx identity use "$selected_identity"
        else
            echo "Identity nie istnieje, tworzę nowe: $selected_identity"
            dfx identity new "$selected_identity"
            dfx identity use "$selected_identity"
        fi
    else
        echo "Identity istnieje, używam: $selected_identity"
        dfx identity use "$selected_identity"
    fi
    break  # Przerywamy pętlę po poprawnym wyborze
done

export MINTER_ACCOUNT_ID=$(dfx identity get-principal)


clear

echo -e "\033[1;36m3️⃣  Podaj pełną nazwę tokena (np. ICP Token, Bamboo Finance itp) 🐧\033[0m"
echo "---------------------------------------------------------------"
read TOKEN_NAME
export TOKEN_NAME

clear

echo -e "\033[1;36m4️⃣  Podaj symbol tokena (np. ICP, BTC, ETH) wielkie litery krótkie 🪷\033[0m"
echo "---------------------------------------------------------------"
read TOKEN_SYMBOL
export TOKEN_SYMBOL

clear

echo -e "\033[1;36m5️⃣  Wybierz identity do przelania mintowanych tokenów 🪪\033[0m"
echo "---------------------------------------------------------------"
echo "Na jakie konto mają ZOSTAĆ PRZELANE WSZYSTKIE TOKENY po wymintowaniu 🪙"
echo "Nie podawaj tego samego konta co mintuje tylko inne  ❌"
echo "Konto mintujące nie może przelewać tokenów ❌ 💸 ⛔️"
echo "---------------------------------------------------------------"
echo " "

identity_list=$(dfx identity list | awk '{print $1}' | tail -n +2)
options=("nowe" $identity_list)

echo "Wybierz identity wpisując liczbę np. 2, 3, 4 itp."
echo "Wybierz 1 aby stworzyć nowe identity ( nowe konto )."
echo "---------------------------------------------------------------"

select deploy_identity in "${options[@]}"; do
    if [ -z "$deploy_identity" ]; then
        echo "Niepoprawny wybór, spróbuj ponownie ❌"
        continue
    fi
    
    if [ "$deploy_identity" == "nowe" ]; then
        echo "Podaj nazwę nowego identity:"
        read deploy_identity
        
        if dfx identity list | grep -q "^$deploy_identity$"; then
            echo "Identity istnieje, używam istniejącego: $deploy_identity"
            dfx identity use "$deploy_identity"
        else
            echo "Identity nie istnieje, tworzę nowe: $deploy_identity"
            dfx identity new "$deploy_identity"
            dfx identity use "$deploy_identity"
        fi
    else
        echo "Wybrane identity: $deploy_identity"
        dfx identity use "$deploy_identity"
    fi
    
    export DEPLOY_ID=$(dfx identity get-principal)
    break
done


clear


echo -e "\033[1;36m6️⃣  Podaj ilość mintowanych tokenów (ILE Tokenów chcesz utworzyć) ❔🪙\033[0m"
echo "---------------------------------------------------------------";
read PRE_MINTED_TOKENS
export PRE_MINTED_TOKENS

clear


echo -e "\033[1;36m7️⃣  Podaj wartość fee transakcji (np. 1,10,100 ALBO 10000 ) 🧮\033[0m"
echo "---------------------------------------------------------------";
echo "Ta ilość tokenów będzie spalana i pobierana z konta nadawcy 🔥🪙"
read TRANSFER_FEE
export TRANSFER_FEE

clear


if dfx identity list | grep -q "archive_controller"; then
    echo "Identity 'archive_controller' już istnieje. Używamy istniejącego."
    dfx identity use archive_controller
else
    echo "Tworzenie nowego identity 'archive_controller'..."
    dfx identity new archive_controller
    dfx identity use archive_controller
fi

export ARCHIVE_CONTROLLER=$(dfx identity get-principal)



export TRIGGER_THRESHOLD=2000
export NUM_OF_BLOCK_TO_ARCHIVE=1000
export CYCLE_FOR_ARCHIVE_CREATION=10000000000000
export FEATURE_FLAGS=true


echo -e "\033[1;36m8️⃣ Wdrażanie canistra... 🚀\033[0m"
dfx deploy icrc1_ledger_canister --argument "(variant {Init = record {
     token_symbol = \"${TOKEN_SYMBOL}\";
     token_name = \"${TOKEN_NAME}\";
     minting_account = record { owner = principal \"${MINTER_ACCOUNT_ID}\" };
     transfer_fee = ${TRANSFER_FEE};
     metadata = vec {};
     feature_flags = opt record { icrc2 = ${FEATURE_FLAGS} };
     initial_balances = vec { record { record { owner = principal \"${DEPLOY_ID}\"; }; ${PRE_MINTED_TOKENS}; }; };
     archive_options = record {
         num_blocks_to_archive = ${NUM_OF_BLOCK_TO_ARCHIVE};
         trigger_threshold = ${TRIGGER_THRESHOLD};
         controller_id = principal \"${ARCHIVE_CONTROLLER}\";
         cycles_for_archive_creation = opt ${CYCLE_FOR_ARCHIVE_CREATION};
     };
  }
})"
