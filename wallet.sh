#!/bin/bash

function join {
    local IFS="$1"
    shift
    echo "$*"
}

function printgold()
{
    local copper=$(($1 % 100))
    local silver=$(($(($(($1 - copper)) / 100)) % 100))
    local gold=$(($(($(($(($1 - copper)) / 100)) - silver)) / 100))
    printf "\e[33m"
    [[ $gold -ne 0 ]] && printf "%dg " "$gold"
    printf "\e[37m"
    [[ $1 -ge 100 ]] && ([[ $1 -ge 10000 ]] && printf "%02ds " "$silver" || printf "%ds " "$silver")
    printf "\e[31m"
    [[ $1 -ge 100 ]] && printf "%02dc" "$copper" || printf "%dc" "$copper"
    printf "\e[0m"
}

function getWallet()
{
    l="$(printf "=%.0s" {1..80})"
    printf "%s\n%s\n%s\n" "$l" "wallet contents (including tradepost delivery)" "$l"

    apikey=$(cat gw2apikey)
    wallet=$(curl "https://api.guildwars2.com/v2/account/wallet?access_token=${apikey}" 2>/dev/null)
    currencies=$(curl "https://api.guildwars2.com/v2/currencies?ids=all" 2>/dev/null)
    delivery=$(curl "https://api.guildwars2.com/v2/commerce/delivery?access_token=${apikey}" 2>/dev/null)
    deliverycoins=$(echo "${delivery}" | jq '.coins')
    ids=($(echo "$wallet" | jq '.[].id'))
    values=($(echo "$wallet" | jq '.[].value'))
    for (( i = 0; i < ${#ids[@]}; i++ )); do
        if [[ ${ids[$i]} -eq 1 ]]; then
            printgold $((${values[$i]} + $deliverycoins))
            gemworth=$(curl https://api.guildwars2.com/v2/commerce/exchange/coins?quantity=$((${values[$i]} + $deliverycoins)) \
                2>/dev/null | jq '.quantity')
            echo -e " worth \e[94m$gemworth gems\e[0m"
        elif [[ ${ids[$i]} -eq 4 ]];then
            echo -en "\e[94m${values[$i]} gems\e[0m"
            coinworth=$(curl https://api.guildwars2.com/v2/commerce/exchange/gems?quantity=${values[$i]} \
                2>/dev/null | jq '.quantity')
            echo -e " worth $(printgold $coinworth)"

        else
            name=$(echo "$currencies" | jq -r ".[] | select(.id == ${ids[$i]})| .name")
            echo ${values[$i]} $name

        fi
    done
}

getWallet
