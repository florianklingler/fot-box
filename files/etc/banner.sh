#/bin/sh

. /etc/openwrt_release
VERSION_CODE=$(cat /etc/openwrt_version)

IPADDR=$(/sbin/ifconfig br-lan | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')

BASE_PORT1=19191
BASE_INTERFACE1=wlan0

BANNERTEXT=$(echo "
------------------------------------------------------------------------
ccs-labs.org     ....,;cccsOKNCCCCCCCCCWKsl,.
             ....''''''.....   ...;:laX0SWCCCN0Xc:'.
   .;laX0SNWCWSK0OXsaacccccaacclcc''''''  '''ccXKWCCWKsl,.
XSCCCSOal'''                          ......      '':aONCCNOc;.
NXc'                .',,;;::ccclcllccccaalc;'.          ''csKWCSXl'
                  ...                    ''''lsXssc:.         'lONCWOc.
                         .':lcc:;,'''''''         ''lXXa:.        'l0CCK
                      .cOa''                           ''aOa,        'lS
                      Ss                                   'cKa.
                      XO                                     'XCX.
                       l0c.                                    OCN,
.                        :O0l'                                 sCCN.
CKl.                        'cXXsl;'.                ..       lCCCC,
KCCCNs;.                         ''ccsXssssssaaaclc:;'     .cKCCCCX
 'cKCCCCSs:.              ...                          .;c0WCCCWO'
    'cXNCCCCNOc;.           '':lcasaclcc:::::cclcasOKNCCCCCNOc'
        ''aONCCCCWKXcc,.           '''':clccasssssacll:'''        ...
             ''ls0NCCCCCCWSOscl:;'...                   ..',:laX0Xl.  .c
                   '''caX0SWCCCCCCCCCCCWNSSSSKKKSSSSNWCCCCWSOa:.   ,aKCC
   '''';:'.                  '''':clccasssXXXXsssaclc:''''  ..;cXSCCCCCC
        ''caO0KOsacc:;,'...                      ...,;ccsOKWCCCCCCCCCCCC
               ''laOKNCCCCCCCWWNSSSSKKKKSSSSNWWCCCCCCCCCCCCCCCCCCCCCWSXc
                       ''''lcsX0KSNWCCCCCCCCCCCCCCCCCCCCCWNS0Xscc'''
                                      '''''''''''''''''


       .lcclssc      ;clclXa.    .cc:csa.
     .0N;    XCS   lNO.   .WCl  lC,    cs
    .NC:      ;.  lCS      .;   lCX'
    cCC'          KCO            ,sSWKa,
    :CC:          0CS               .;OCK
     0CN,      ;  ,WCO.     .. .K      KC'
      lKW0l:cac.   .sNWsc:la:   S0;..'c0:
         ''''         '''''      '''''

...by CCS-Labs.org.    Version ${VERSION_CODE}          
------------------------------------------------------------------------ 
                                                                
Based on ${DISTRIB_ID} ${DISTRIB_RELEASE} (openwrt.org)    
LAN interface IPv4: ${IPADDR}                                   
                                                                
Contact: http://www.ccs-labs.org/~klingler/                     
========================================================================")

