#!/bin/bash

for i in 100000
do
while IFS= read -r pop
do
norm --bp-win --xpnsl --qbins 10 --winsize ${i} --files \
XPNSL/${pop}_CP018157.1.xpnsl.out	\
XPNSL/${pop}_CP018158.1.xpnsl.out	\
XPNSL/${pop}_CP018159.1.xpnsl.out	\
XPNSL/${pop}_CP018160.1.xpnsl.out	\
XPNSL/${pop}_CP018161.1.xpnsl.out	\
XPNSL/${pop}_CP018162.1.xpnsl.out	\
XPNSL/${pop}_CP018163.1.xpnsl.out	\
XPNSL/${pop}_CP018164.1.xpnsl.out	\
XPNSL/${pop}_CP018165.1.xpnsl.out	\
XPNSL/${pop}_CP018166.1.xpnsl.out	\
XPNSL/${pop}_CP018167.1.xpnsl.out	\
XPNSL/${pop}_CP018168.1.xpnsl.out
done < K12_pops.txt
done
