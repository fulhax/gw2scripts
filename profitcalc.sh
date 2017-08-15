#!/bin/zsh

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

function tocopper()
{
    gold=$(echo $1 | perl -ne '/([\d\.]+)g/i && print "$1";')
    silver=$(echo $1 | perl -ne '/([\d\.]+)s/i && print "$1";')
    copper=$(echo $1 | perl -ne '/(\d+)c/i && print "$1";')

    if [ -z $gold ] && [ -z $silver ] && [ -z $copper ]; then
        echo "$1"
    else
        total=$((
                $((gold * 10000)) +
                $((silver * 100)) +
                copper
            ))
        echo "$total"
    fi
}

if [ $# -lt 2 ]; then
    echo "Usage: [BUY] [SELL] [COUNT]"
    exit 0
fi

COUNT=1
[ $# -ge 3 ] && COUNT="$3"

BC=$(tocopper "$1")
SC=$(tocopper "$2")

SELL="$((SC * COUNT))"
BUY="$((BC * COUNT))"

TOTAL=$(($SELL - $BUY))
FEE=$((SELL * 0.05))
TAX=$((SELL * 0.10))

[ $(printf "%d" "$FEE") -eq 0 ] && FEE=1
[ $(printf "%d" "$TAX") -eq 0 ] && TAX=1

PROFIT=$((TOTAL - FEE - TAX))

printf "Sale: %s\n" "$(printgold $SELL)"
printf "Cost: %s\n" "$(printgold $BUY)"
printf "Fee (-5%%): %s\n" "$(printgold $FEE)"
printf "Tax (-10%%): %s\n\n" "$(printgold $TAX)"

COLOR="\e[32m"
TEXT="Profit"
if [[ $PROFIT -le 0 ]]; then
    COLOR="\e[31m"
    TEXT="Loss"
fi

printf "Invest: %s\n" "$(printgold "$((BUY + FEE + TAX))")"
printf "${COLOR}${TEXT}: %s${COLOR} (%d%%)\e[0m\n" \
    "$(printgold $PROFIT)" "$(((PROFIT / BUY) * 100))"
