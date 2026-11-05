* 1N4007 Diode
*
* SPICE (Simulation Program with Integrated Circuit Emphasis)
* MODEL
*
* Connections:     A
*                  |    C
*                  |    |
*                  1    2
.MODEL 1N4007 D(IS=403P N=1.57 BV=1K IBV=10U RS=43.2M
+ CJO=52.8P VJ=300M MJ=272M FC=500M TT=7.93U
+ EG=1.11 XTI=3 KF=0 AF=1)
.END