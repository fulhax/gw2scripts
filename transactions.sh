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

function getSaleBuyList()
{
    l="$(printf "=%.0s" {1..80})"
    printf "%s\n%s\n%s\n" "$l" "$1" "$l"

    apikey=$(cat gw2apikey)
    buys=$(curl "https://api.guildwars2.com/v2/commerce/transactions/${1}?access_token=${apikey}" 2>/dev/null)
    echo "$buys" > lastbuysfile
    prices=($(echo "${buys}" | jq '.[].price'))
    amount=($(echo "${buys}" | jq '.[].quantity'))
    itemid=($(echo "${buys}" | jq '.[].item_id'))

    total=0

    search=$(join , "${itemid[@]}" | uniq)

    items=$(curl "https://api.guildwars2.com/v2/items?ids=$search" 2>/dev/null)
    pricelist=$(curl "https://api.guildwars2.com/v2/commerce/prices?ids=$search" 2>/dev/null)
    IFS=$'\n'

    for (( i = 0; i < "${#itemid[@]}"; i++ )); do
        curr=${itemid[$i]}
        name=$(echo "$items" | jq -r ".[] | select(.id == $curr)| .name")
        count=${amount[$i]}
        price=${prices[$i]}

        instantprice=$(echo "$pricelist" | \
            jq -r ".[] | select(.id == $curr)| .buys.unit_price")
        slowprice=$(echo "$pricelist" | \
            jq -r ".[] | select(.id == $curr)| .sells.unit_price")

        thisprice=$((count * price))
        printf "%-4s %-40s %32s each:%32s buyorder: %32s sell: %32s\n" \
            "${amount[$i]}x" \
            "$name" \
            "$(printgold "$thisprice")" \
            "$(printgold "$price")" \
            "$(printgold "$instantprice")" \
            "$(printgold "$slowprice")"

        total=$((total + thisprice))
    done

    echo "total $(printgold $total)"
}

function printhelp
{
    echo "valid options"
    echo "-c = current instead of history"
    echo "-s = show sales/for sale"
    echo "-b = show bought/buy orders"
}

[[ $# -eq 0 ]] && printhelp

scope="history"
while getopts "hcsb" c;do
    case "$c" in
        h)
            printhelp
            exit 0
            ;;

        c)
            scope="current"
            ;;

        s)
            showsales=1
            ;;

        b)
            showbuys=1
            ;;

        \?)
            echo "invalid option $c"
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done
if [[ $showsales -eq 1 ]]; then
    getSaleBuyList "${scope}/sells"
fi
if [[ $showbuys -eq 1 ]]; then
    getSaleBuyList "${scope}/buys"
fi
