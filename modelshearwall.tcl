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
uniaxialMaterial Elastic 2 320000000
#test2
#uniaxialMaterial Elastic 2 640000000

#node for column and beam
node 1 0 0
node 2 $length 0
node 3 0 $height
node 4 $length $height

#node for hinge
#the distance from center of column to the hinge(center of RBS)
set beamoffset 157
set hingeL 0.5
node 5 $beamoffset $height
node 6 [expr $length-$beamoffset] $height


#constraints for column bottom
fix 1 1 1 0
fix 2 1 1 0

node 11 0 0
node 22 $length 0
fix 11 1 1 1
fix 22 1 1 1

#column bottom
element zeroLength 11 1 11 -mat 2 -dir 4 -orient 0 0 1 0 1 0
element zeroLength 21 2 22 -mat 2 -dir 4 -orient 0 0 1 0 1 0

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
    patch rect 1 10 1 [expr $y12-$beamt1] [expr $z22] [expr -$y12+$beamt1] [expr -$z22]
}

#RBS section
set RBSwidth 60
set RBSheight 100
set RBSt1 8
set RBSt2 6
set y13 [expr $RBSheight/2]
set z13 [expr $RBSwidth/2]
set z23 [expr $RBSt2/2]
section Fiber 3 {
#top Flange
	patch rect 1 1 10 [expr $y13] [expr $z13] [expr $y13-$RBSt1] [expr -$z13]
#bottom Flange	
	patch rect 1 1 10 [expr -$y13+$RBSt1] [expr $z13] [expr -$y13] [expr -$z13]
#web
    patch rect 1 10 1 [expr $y13-$RBSt1] [expr $z23] [expr -$y13+$RBSt1] [expr -$z23]
}

#element
geomTransf Linear 1
#geomTransf PDelta 1
geomTransf Linear 2 
#element forceBeamColumn $eleTag $iNode $jNode $numIntgrPts $secTag $transfTag  
#ele of column 
element forceBeamColumn 1 1 3 5 1 1
element forceBeamColumn 2 2 4 5 1 1
#ele of beam

element forceBeamColumn 3 3 5 5 2 2
#element with RBS
#element forceBeamColumn $eleTag $iNode $jNode $transfTag "HingeRadau $secTagI $LpI $secTagJ $LpJ $secTagInterior"
element forceBeamColumn 4 5 6 2 "HingeRadau 3 $hingeL 3 $hingeL 2"  
#element forceBeamColumn 4 5 6 5 2 1
element forceBeamColumn 5 6 4 5 2 2

set P 1
pattern Plain 1 "Linear"  {
	load 4 $P 0 0
}

constraints Plain
numberer RCM
system SparseGEN
test NormDispIncr 1.0e-12 30
algorithm Newton
integrator LoadControl 1
analysis Static
analyze 1

#loadConst -time 0.0

#cyclic loading
recorder Node -file node3disp.out -time -node 4 -dof 1 disp
#recorder Node -file node3rec.out -node 4 -dof 1 reaction
set dU 0.1








set ok 0
set currentDisp 0
set maxU 20
for {set i 10} {$i<120} {incr i 10} {
integrator DisplacementControl 4 1 $dU 1 $dU $dU
set targetU [expr $i*$maxU/100]

while {$ok == 0 && $currentDisp <= $targetU} {
	set ok [analyze 1]

	if {$ok !=0} {
		puts "rugular iteration failed change another one"
		algorithm ModifiedNewton -initial
		test NormDispIncr 1.0e-12 1000
		set ok [analyze 1]
		if {$ok ==0 } {
			puts "initial modifiedNewton successful change into rugular one"
			algorithm Newton
		}
	}
	set currentDisp [nodeDisp 4 1]
}

if {$ok == 0} {
	puts "target $targetU successful"
} else {puts "target $targetU failed"}

integrator DisplacementControl 4 1 -$dU 1 -$dU -$dU
set targetU [expr -$i*$maxU/100]

while {$ok == 0 && $currentDisp >= $targetU} {
	set ok [analyze 1]

	if {$ok !=0} {
		puts "rugular iteration failed change another one"
		algorithm ModifiedNewton -initial
		test NormDispIncr 1.0e-12 1000
		set ok [analyze 1]
		if {$ok ==0 } {
			puts "initial modifiedNewton successful change into rugular one"
			algorithm Newton
		}
	}
	set currentDisp [nodeDisp 4 1]
}

if {$ok == 0} {
	puts "target $targetU successful"
} else {puts "target $targetU failed"}

}