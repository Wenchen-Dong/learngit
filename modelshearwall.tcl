#clean all things
wipe
#unit mm t N s Mpa mm/s2 mJ
#model dimensions and DOF
model BasicBuilder -ndm 2 -ndf 3

#parameter
set height 1650
set length 2400


#steel
uniaxialMaterial Steel01 1 235 206e3 0.02
#column bottom material to simulate the rotational stiffness
uniaxialMaterial Elastic 2 640000000

#node for column and beam
node 1 0 0
node 2 $length 0
node 3 0 $height
node 4 $length $height


#constraints for column bottom
fix 1 1 1 0
fix 2 1 1 0

node 11 0 0
node 22 $length 0
fix 11 1 1 1
fix 22 1 1 1

#column bottom
element zeroLength 4 1 11 -mat 2 -dir 4 -orient 0 0 1 0 1 0
element zeroLength 5 2 22 -mat 2 -dir 4 -orient 0 0 1 0 1 0

#width,height of column and thickness of flange and web
set colwidth 125
set colheight 125
set colt1 9
set colt2 6.5
set y1 [expr $colheight/2]
set z1 [expr $colwidth/2]
set z2 [expr $colt2/2]
section Fiber 1 {
#top Flange
	patch rect 1 1 10 [expr $y1] [expr $z1] [expr $y1-$colt1] [expr -$z1] 
#bottom Flange	
	patch rect 1 1 10 [expr -$y1+$colt1] [expr $z1] [expr -$y1] [expr -$z1]
#web
    patch rect 1 10 1 [expr $y1-$colt1] [expr $z2] [expr -$y1+$colt1] [expr -$z2]
}

#width,height of beam and thickness of flange and web
set beamwidth 100
set beamheight 100
set beamt1 8
set beamt2 6
set y12 [expr $beamheight/2]
set z12 [expr $beamwidth/2]
set z22 [expr $beamt2/2]
section Fiber 2 {
#top Flange
	patch rect 1 1 10 [expr $y12] [expr $z12] [expr $y12-$beamt1] [expr -$z12]
#bottom Flange	
	patch rect 1 1 10 [expr -$y12+$beamt1] [expr $z12] [expr -$y12] [expr -$z12]
#web
    patch rect 1 10 1 [expr $y1-$beamt1] [expr $z22] [expr -$y12+$beamt1] [expr -$z22]
}

#element
geomTransf Linear 1
#geomTransf PDelta 1
geomTransf Linear 2 
#element forceBeamColumn $eleTag $iNode $jNode $numIntgrPts $secTag $transfTag   
element forceBeamColumn 1 1 3 5 1 1
element forceBeamColumn 2 2 4 5 1 1
element forceBeamColumn 3 3 4 5 2 1

set P 20000
pattern Plain 1 "Linear"  {
	load 3 $P 0 0
}

constraints Plain
numberer RCM
system SparseGEN
test NormDispIncr 1.0e-12 30
algorithm Newton
integrator LoadControl 1
analysis Static
analyze 1

print -node 3 4
print ele 3