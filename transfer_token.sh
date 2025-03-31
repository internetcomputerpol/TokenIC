#!/bin/bash


echo "Kim jesteś (aktualne identity 🪪):"
dfx identity whoami
echo "---------------------------------------------------------------"

echo "Lista dostępnych identity 🧾 :"
dfx identity list
echo "---------------------------------------------------------------"


echo "Czy chcesz przelogować się na inne identity 👤 ? Wpisz tak lub nie)"
read switch_identity


if [ "$switch_identity" == "tak" ]; then
    echo "Podaj nazwę identity, na które chcesz się przelogować:"
    read identity_name
    dfx identity use "$identity_name" &>/dev/null
    echo "Przelogowano na identity: $identity_name"
else
    echo "Kontynuuję z bieżącym identity..."
fi


echo "Podaj ID principala do którego chcesz wysłać przelew 🪪:"
read recipient_principal


echo "Podaj ilość tokenów, które chcesz przelać ⚖️:"
read token_amount

if [ -z "$recipient_principal" ] || [ -z "$token_amount" ]; then
    echo "Błąd: Musisz podać zarówno principal, jak i ilość tokenów."
    exit 1
fi


echo "Wykonuję przelew...⌛️"
dfx canister call bkyz2-fmaaa-aaaaa-qaaaq-cai icrc1_transfer "(record {
  to = record {
    owner = principal \"$recipient_principal\";
  };
  amount = $token_amount;
})"

echo "---------------------------------------------------------------"
echo "Przelew wykonany 💸."
