#!/bin/bash

function join {
    local IFS="$1"
    shift
    echo "$*"
}

function printgold()
{
    local copper=$(($1 % 100))
    local silver=$(($(($(($1 - $copper)) / 100)) % 100))
    local gold=$(($(($(($(($1 - $copper)) / 100)) - $silver)) / 100))

    [[ ${gold} -ne 0 ]] && printf "\e[33m%dg " "${gold}"
    [[ ${silver} -ne 0 ]] && printf "\e[37m%ds " "${silver}"
    [[ ${copper} -ne 0 ]] && printf "\e[31m%dc" "${copper}"
    printf "\e[0m"
}

function getjson()
{
    local regex="$2:[ ]\+\"\?\\([^\"]\\+\\)\"\?,"
    echo "$1" | grep "$2" | sed -e "s/$regex/\1/" | sed -e 's/^ *//'
}
function getSaleBuyList()
{
    echo "================================================================================"
    echo $1
    echo "================================================================================"
    apikey=$(cat gw2apikey)
    buys=$(curl "https://api.guildwars2.com/v2/commerce/transactions/${1}?access_token=${apikey}" 2>/dev/null)
    prices=($(getjson "${buys}" '"price"'))
    amount=($(getjson "${buys}" '"quantity"'))
    itemid=($(getjson "${buys}" '"item_id"'))

    declare -A lookup

    total=0

    search=$(join , "${itemid[@]}")
    items=$(curl "https://api.guildwars2.com/v2/items?ids=$search" 2>/dev/null)
    pricelist=$(curl "https://api.guildwars2.com/v2/commerce/prices?ids=$search" 2>/dev/null)
    #
    IFS=$'\n'
    item=($(getjson "${items}" '"name"'))
    id=($(getjson "${items}" '^    "id"'))
    marketvalues=($(getjson "${pricelist}" "unit_price"))
    marketid=($(getjson "${pricelist}" '"id"'))

    for (( i = 0; i < "${#id[@]}"; i++ )); do
        lookup+=( [${id[$i]}]=${item[$i]} )
    done

    for (( i = 0; i < "${#itemid[@]}"; i++ )); do
        curr=${itemid[$i]}
        name=${lookup[$curr]}
        count=${amount[$i]}
        price=${prices[$i]}

        thisprice=$((count * price))

        printf "%-3s %-40s %-14s\n" \
            "${amount[$i]}x" "$name" "$(printgold ${thisprice})"

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
