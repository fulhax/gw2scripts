#!/bin/bash
function join
{
    local IFS="$1"
    shift
    echo "$*"
}
mkdir -p cache/item
pushd cache

if [[ ! -f items ]]; then
    echo fetching itemids
    curl https://api.guildwars2.com/v2/items 2>/dev/null > items
fi

itemids=($(cat items | jq '.[]'))

numberofitems=$(echo "${#itemids[@]}")

echo $numberofitems $(($numberofitems / 200))
for (( i = 0; i < $numberofitems; i+= 200 )); do
    search=$(join , "${itemids[@]:$i:200}" | uniq)
    #curl https://api.guildwars2.com/v2/items?ids=$search 2>/dev/null | jq '.[].id' | wc -l
    fetchmore=0
    for id in "${itemids[@]:$i:200}"; do
        if [[ ! -f ./item/$id ]]; then
            fetchmore=1
        fi
    done
    if [[ fetchmore -eq 1 ]]; then
        echo "fetching items ${itemids[$i]} to ${itemids[$(($i + 200))]}"
        itemfile=$(curl https://api.guildwars2.com/v2/items?ids=$search 2>/dev/null)
        for id in "${itemids[@]:$i:200}"; do
            echo "$itemfile" | jq ".[] | select(.id == $id)" > ./item/$id
        done
    fi
done

popd
