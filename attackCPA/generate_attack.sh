#!/bin/bash


for i in {1..1000}
do
   ./target_AES -o tmp/$i.out $(./ext/bin/random_bytes 16)
done

for i in {0..15}
do
    c=$((519+$((7*$i))))
    x='toto'$i
    ./attackCPA $i $c 'data/'$x tmp/*
    ./ext/bin/CPA_guess_key 'data/'$x
done

