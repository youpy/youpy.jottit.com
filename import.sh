#!/bin/sh
# go get github.com/youpy/go-jottit/jottit

set -e -x

tmp=/tmp/jottit_revs.txt.$$
site=youpy.jottit.com

rm -f $tmp
mkdir -p pages

# ignore debu
for page in $(jottit -name $site -list | grep -v debu)
do
    for rev in $(jottit -page $page -revisions)
    do
        set +e

        time=$(jottit -page $page -revision $rev -time)
        if [ $? -ne 0 ]; then
            continue
        fi

        echo "$page\t$rev\t$time" >> $tmp

        set -e
    done
done

sort -n -k 3 $tmp | while read line
do
    set +e

    page=$(echo "$line" | cut -f1)
    rev=$(echo "$line" | cut -f2)
    date=$(echo "$line" | cut -f3 | TZ=UTC LC_ALL=C xargs -I{} gdate -d "@{}")

    file=pages/$(echo $page | cut -d/ -f 4).md
    name=$(echo $file | xargs -I@ perl -MURI::Escape -e "print uri_unescape('@')")

    jottit -page $page -revision $rev -content > $file
    if [ $? -ne 0 ]; then
        continue
    fi

    # # ignore SPAM
    # if expr "$(cat $file)" : "^[a-z]...................," > /dev/null; then
    #     continue
    # fi

    git add $file
    git ci --date="$date" -m "commit $name rev:$rev"

    set -e
done
