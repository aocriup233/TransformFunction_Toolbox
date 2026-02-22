.SUBCKT MOS_SPICE D G S B PARAMS: gm=1m gmb=0.2m ro=10k cgs=0.2p cgd=50f cgb=50f cdb=20f csb=20f

Rgs G S 1e12
Rbs B S 1e12
Gm D S POLY(1) G S 0 {gm}
Gmb D S POLY(1) B S 0 {gmb}
Rds D S {ro}
Cgs G S {cgs}
Cgd G D {cgd}
Cgb G B {cgb}
Cdb D B {cdb}
Csb S B {csb}

.ENDS MOS_SPICE