breed [basic-agent basicagent]
breed [expert-agent expertagent]
turtles-own[energy]

globals [
  total-yellow-food ; the total amount of yellow food in the map
  total-green-food ; the total amount of green food in the map
  total-shelters-destroyed ; the total amount of shelters in the map that were destroyed
  restore-food ; a prop used to verify if the food should be restored ( 2 ticks per time )
  ;expert-kill-basic-min-energy ;  if the basic agent is detected by an expert and the basic have less that the configured amount of energy, he dies
  ;basic-agent-camouflage-percentage ; if a random number is bigger that the basic agent camouflage percentage the agent dies from the expert when detected, if not he stays alive
]

expert-agent-own[
  experience
  total-yellow-food-eaten
  total-yellow-food-eaten-temp
  total-green-food-eaten
  total-green-food-eaten-temp
  shelter-tick-count
]



; ==================================
; setup procedures start here
; ==================================
to setup-agent-generic ; procedure that shares properties among the turtles/agents
  set energy 100
  ;show "my current energy is 100"
end

to setup-agent-basic
  create-basic-agent n-basic-agent[
    set shape "bug"
    set color 135
  ]

  ask basic-agent [

    let x 0
    let y 0

    ask one-of patches with [pcolor = 35] [
      set x pxcor
      set y pycor
    ]
     setxy x y
  ]
end

to setup-agent-expert
  create-expert-agent n-expert-agent[
    set experience 0
    set total-yellow-food-eaten 0
    set total-yellow-food-eaten-temp 0
    set total-green-food-eaten 0
    set total-green-food-eaten-temp 0
    set shelter-tick-count 0
    set shape "butterfly"
    set color 85
  ]

  ask expert-agent [

    let x 0
    let y 0

    ask one-of patches with [pcolor = 35] [
      set x pxcor
      set y pycor
    ]
     setxy x y
  ]
end

to setup-agents ; main procedure that initializes the agents
  setup-agent-basic
  setup-agent-expert
  ask turtles [setup-agent-generic]; this will set the properties inside the procedure to all turtles
end

to setup-patches-green-food
  ask n-of ((green-food-percentage / 100) * count patches ) patches with [ pcolor = 35 ] [ ; 35 is the color of the ambient, this verification is to avoid changing patches and already have been defined as a food, trap or shelter
      set pcolor green
  ]

  set total-green-food (count patches with [pcolor = green])
  show total-green-food
end

to setup-patches-yellow-food
  ask n-of ((yellow-food-percentage / 100) * count patches ) patches with [ pcolor = 35 ] [; 35 is the color of the ambient, this verification is to avoid changing patches and already have been defined as a food, trap or shelter
      set pcolor yellow
  ]

  set total-yellow-food (count patches with [pcolor = yellow])
  show total-yellow-food
end

to setup-patches-red-trap
  ask n-of ((trap-percentage / 100) * count patches ) patches with [ pcolor = 35 ] [ ; 35 is the color of the ambient, this verification is to avoid changing patches and already have been defined as a food, trap or shelter
      set pcolor red
  ]
end

to setup-patches-blue-shelter
  let x 0
  ask patches with [ pcolor = 35 ] [ ; 35 is the color of the ambient, this verification is to avoid changing patches and already have been defined as a food, trap or shelter
    if x < n-shelter
    [
      set pcolor blue
      set x x + 1
    ]
  ]
end

to setup-patches ; main procedure that initializes the patches
  ask patches[
    set pcolor 35
  ]
  setup-patches-green-food
  setup-patches-yellow-food
  setup-patches-red-trap
  setup-patches-blue-shelter
end

to setup-globals
  set restore-food 0
  ;set expert-kill-basic-min-energy 50
  ;set basic-agent-camouflage-percentage 30
  set total-shelters-destroyed 0
end

to setup
  print "----------------------------"
  print " -------- new game -------- "
  print "----------------------------"
  clear-all
  clear-output
  reset-ticks
  setup-patches
  setup-agents
  setup-globals
end

; ==================================
; setup procedures end here
; ==================================

; ==================================
; handle iterations procedures starts here
; ==================================

; -------  start of basic agent actions -------

to-report handle-basic-agent-interaction

  let energy-stealed 0
  let energy-losted 0

  if count expert-agent-on patch-ahead 1 > 0 [
    if pcolor != blue [
      ask one-of expert-agent-on patch-ahead 1[
        if experience < 50[
          set energy-stealed energy * 0.5
          set energy energy - energy-stealed
        ]
        if experience >= 50[
          set energy-losted energy * 0.1

        ]
        if energy-stealed > 0[
          set energy energy + energy-stealed
        ]
        if energy-losted > 0[
          set energy energy - energy-losted
        ]
      ]
    ]
  ]

  if count expert-agent-on patch-right-and-ahead 90 1 > 0 [
    if pcolor != blue [
      ask one-of expert-agent-on patch-right-and-ahead 90 1[
        if experience < 50[
          set energy-stealed energy * 0.5
          set energy energy - energy-stealed


        ]
        if experience >= 50[
          set energy-losted energy * 0.1

        ]
        if energy-stealed > 0[
          set energy energy + energy-stealed
        ]
        if energy-losted > 0[
          set energy energy - energy-losted
        ]
      ]
    ]
  ]

  report 0
end

to-report handle-basic-agent-food ; reactive agent without memory

  let action-available 1 ; agent can move
  let virtual-energy energy
  let virtual-agent-eaten-food 0
  ask patch-here[
    (
      if pcolor = yellow [
        set pcolor black;
        set virtual-agent-eaten-food 1
      ]
    )
  ]
  if virtual-agent-eaten-food = 1[
    set energy energy + 10
    report 1
  ]

  if [pcolor] of patch-ahead 1 = yellow[
    fd 1
    report nobody
  ]

  if [pcolor] of patch-right-and-ahead 90 1 = yellow[
    rt 90
    report nobody
  ]

  ;if there isnt any move for food
  fd 1
  report nobody

end

to-report handle-basic-agent-trap
  ; the agent have perceived a trap?
  ; if the energy < 100 agent dies
  ; if the energy > 100 agent takes 10% damage

  let virtual-basic-agent-should-die 0
  let action-basic-executed 0

  ;if the agent is availabe for a move
  if [pcolor] of patch-ahead 1 = red [
    if energy < 100[
    set virtual-basic-agent-should-die 1
  ]
    if energy >= 100[
      let virtual-basic-energy-taken energy * 0.10
      set energy energy - virtual-basic-energy-taken
      rt 90
      set action-basic-executed 1
    ]
  ]

  ; verification if the agente perceived any trap patch-ahead
  if virtual-basic-agent-should-die = 1 [report 2]; make it die
  if action-basic-executed = 1 [report 1] ; make it took energy

  ;the agent have perceived a trap on the right?
    if [pcolor] of patch-right-and-ahead 90 1 = red[
      if energy < 100[
        set virtual-basic-agent-should-die 1
      ]
      if energy >= 100[
        let virtual-basic-energy-taken energy * 0.10
        set energy energy - virtual-basic-energy-taken
        rt 90
        set action-basic-executed 1
      ]
  ]

    if virtual-basic-agent-should-die = 1 [report 2]
    if action-basic-executed = 1 [report 1]

    report 0
end

to-report handle-basic-agent-shelter

  let action-basic-executed  0
  let basic-agent-in-shelter 0


  ask patch-here[
    if pcolor = blue [
      set basic-agent-in-shelter 1
      set pcolor 35
      set total-shelters-destroyed  total-shelters-destroyed + 1
    ]
  ]

  if basic-agent-in-shelter = 1 [
    fd 1
    set energy energy + (energy * 0.50)
    set action-basic-executed 1
  ]


  if action-basic-executed = 0 [
    if [pcolor] of patch-ahead 1 = blue [
      let shelter-occupied 1

      if count expert-agent-on patch-ahead 1 = 0 [
        set shelter-occupied 0
      ]

      if shelter-occupied = 1 [

        ;if is expert on it , lose 5% energy
        let virtual-basic-energy-taken energy * 0.05
        set energy energy - virtual-basic-energy-taken
        rt 90
        set action-basic-executed 1
      ]
      if shelter-occupied = 0 [
        ;if is empty , go for the shelter to destroy it
        fd 1
        set action-basic-executed 1
      ]
    ]
  ]

  if action-basic-executed = 0 [
    if [pcolor] of patch-right-and-ahead 90 1 = blue [
      let shelter-occupied 1

      if count expert-agent-on patch-right-and-ahead 90 1 = 0 [
        set shelter-occupied 0
      ]
      if shelter-occupied = 1 [

        ;if is expert on it , lose 5% energy
        let virtual-basic-energy-taken energy * 0.05
        set energy energy - virtual-basic-energy-taken
        rt 90
        set action-basic-executed 1
      ]
      if shelter-occupied = 0 [
        ;if is empty , rotate to it and go for it
        rt 90
        set action-basic-executed 1
      ]
    ]
  ]

  (
    ifelse
    action-basic-executed = 1 [
      report 1
    ]
    action-basic-executed = 0 [
      report 0
    ]
   )

end

to handle-basic-agent
  ask basic-agent
  [
    let action-available 1
    ; perception foward and right (shelters,food,traps and agents)
    ; actions: foward, rotate 90 right
    ; action = energy -1

    let action-agent-interaction handle-basic-agent-interaction

    ; trap action logic
    let action-trap handle-basic-agent-trap
    if action-trap = 1 [
      set action-available 0
    ]
    if action-trap = 2 [
      set action-available 0
      die
    ]

    ; verify if the agent have a action available to verify the shelter
    if action-available = 1 [
      let action-shelter handle-basic-agent-shelter
      if action-shelter = 1 [
        set action-available 0
      ]
    ]

    ; verify if there's any action available to eat food
    if action-available = 1 [
      let action-food handle-basic-agent-food
    ]

    set energy energy - 1
  ]
end


;  --------start of expert agent actions -------
to-report handle-expert-agent-interaction
  ; does the agent perceived a basic agent? (only one)

  let energy-stealed 0

  if count basic-agent-on patch-ahead 1 > 0 [
    ; get only one basic-agent to target
    ask one-of basic-agent-on patch-ahead 1 [
      if random 99 > basic-agent-camouflage-percentage [
        if energy < expert-kill-basic-min-energy [
          ; get half of his energy
          set energy-stealed energy-stealed + (energy * 0.5)
          ; kill him
          show "a expert agent killed me"
          die
        ]
      ]
    ]
  ]

  if count basic-agent-on patch-left-and-ahead 90 1 > 0 [
    ; get only one basic-agent to target
    ask one-of basic-agent-on patch-left-and-ahead 90 1 [
      if random 99 > basic-agent-camouflage-percentage [
        if energy < expert-kill-basic-min-energy [
          ; get half of his energy
          set energy-stealed energy-stealed + (energy * 0.5)
          ; kill him
          show "a expert agent killed me"
          die
        ]
      ]
    ]
  ]


  if count basic-agent-on patch-right-and-ahead 90 1  > 0 [

    ; get only one basic-agent to target
    ask one-of basic-agent-on patch-right-and-ahead 90 1 [
      if random 99 > basic-agent-camouflage-percentage [
        if energy < expert-kill-basic-min-energy [
          ; get half of his energy
          set energy-stealed energy-stealed + (energy * 0.5)
          ; kill him
          show "a expert agent killed me"
          die

        ]
      ]
    ]
  ]

  (
    ifelse
    energy-stealed > 0 [
      set energy energy + energy-stealed
      ;show "my current energy is : "
      ;show energy
      ;show " i stealed "
      ;show energy-stealed
      report 1
    ]
    energy-stealed <= 0 [
      report 0
    ]
  )

end

to-report handle-expert-agent-trap
  ; the agent have perceived a trap ahead?
  let virtual-agent-should-die 0
  let action-executed 0

  if [pcolor] of patch-ahead 1 = red [
    ; if the experience > 50 does not take damage
    if experience >= 50 [
      rt 90 ; rotate to right ignoring the trap
      set action-executed 1
      ;show "im imune to trap ahead because i have more than 50 exp - just avoiding it"
    ]

    if experience < 50 [
      (ifelse
        ; if experience < 50 units and energy >= 100 units it takes 10% damage
        energy >= 100 [
          let virtual-energy-taken energy * 0.10
          set energy energy - virtual-energy-taken
          rt 90; rotate to right ignoring the trap
          set action-executed 1
        ]
        ; if experience < 50 units and energy < 100 units the agent dies
        energy < 100 [
          ;show "im dying from a trap ahead"
          set virtual-agent-should-die 1
        ]
      )
    ]
  ]

  ; verification if the agent perceived a trap in the patch-ahead
  if virtual-agent-should-die = 1 [report 2]
  if action-executed = 1 [ report 1]

  ; the agent have perceived a trap on the left?
  if [pcolor] of patch-left-and-ahead 90 1 = red [
    ; if the experience > 50 does not take damage
    if experience >= 50 [
      rt 90 ; rotate to right ignoring the trap
      set action-executed 1
      ;show "im imune to trap on the left because i have more than 50 exp - just avoiding it"
    ]

    if experience < 50 [
      (ifelse
        ; if experience < 50 units and energy >= 100 units it takes 10% damage
        energy >= 100 [
          let virtual-energy-taken energy * 0.10
          set energy energy - virtual-energy-taken
          rt 90; rotate to right ignoring the trap
          set action-executed 1
        ]
        ; if experience < 50 units and energy < 100 units the agent dies
        energy < 100 [
          ;show "im dying from a trap on the left"
          set virtual-agent-should-die 1
        ]
      )
    ]
  ]

  ; verification if the agent perceived a trap in the patch-left-and-ahead
  if virtual-agent-should-die = 1 [report 2]
  if action-executed = 1 [report 1]

  ; the agent have perceived a trap on the right?
  if [pcolor] of patch-right-and-ahead 90 1 = red [
    ; if the experience > 50 does not take damage
    if experience >= 50 [
      rt -90 ; rotate to left ignoring the trap on the right
      set action-executed 1
      ;show "im imune to trap on the right because i have more than 50 exp - just avoiding it"
    ]

    if experience < 50 [
      (ifelse
        ; if experience < 50 units and energy >= 100 units it takes 10% damage
        energy >= 100 [
          let virtual-energy-taken energy * 0.10
          set energy energy - virtual-energy-taken
          rt -90; rotate to left ignoring the trap
          set action-executed 1
        ]
        ; if experience < 50 units and energy < 100 units the agent dies
        energy < 100 [
          ;show "im dying from a trap on the right"
          set virtual-agent-should-die 1
        ]
      )
    ]
  ]

  ; verification if the agent perceived a trap in the patch-left-and-ahead
  if virtual-agent-should-die = 1 [report 2]
  if action-executed = 1 [report 1]

  report 0
end

to-report handle-expert-agent-shelter

  let action-executed 0

  ; does the agent perceives a shelter? is a shelter in my current position? is it occupied?
  let agent-in-shelter 0
  let agent-receive-rewards 0

  ask patch-here[
    if pcolor = blue [
      set agent-in-shelter 1
    ]
  ]

  if agent-in-shelter = 1[
    set shelter-tick-count shelter-tick-count + 1
  ]

  if shelter-tick-count >= 10 [
    set agent-receive-rewards 1
  ]

  if agent-in-shelter = 1 [

    if agent-receive-rewards = 1 [
      set energy energy + 500
      set experience experience + 25
      set shelter-tick-count 0
      ;show "leaving the shelter after 10 ticks and received rewards"
      fd 1; move foward
      report 1 ; one because the agent needs to leave the shelter immediatly
    ]

    set shelter-tick-count shelter-tick-count + 1
    report 1 ; stay in shelter until tick-count reaches 10
  ]

  ; if the agent is not in the shelter, verify if he perceives one
  if [pcolor] of patch-ahead 1 = blue [
    ; shelter occupied? cannot enter  (report 1 avoid it )
    let shelter-occupied 1

    if count expert-agent-on patch-ahead 1 = 0 [
      set shelter-occupied 0
    ]

    if shelter-occupied = 1 [
      rt -90 ; ignore the shelter since is occupied
      report 1 ;avoiding the shelter
    ]

    if shelter-occupied = 0 [
      ; verify conditions to enter
      ; shelter entrance rule = (energy < 500  && experience < 25 )? true: false
      if energy < 500 and experience < 25 [
        fd 1 ; go to the shelter
        report 1; move to the shelter
      ]

      if energy >= 500 or experience >= 25 [
        ;show "i have more energy or experience that is allowed to enter in the shelter - avoiding :("
        rt -90; ignoring the shelter
        report 1
      ]
    ]

  ]

  if [pcolor] of patch-left-and-ahead 90 1 = blue [
    ; shelter occupied? cannot enter  (report 1 avoid it )
    let shelter-occupied 1

    if count expert-agent-on patch-left-and-ahead 90 1 = 0 [
      set shelter-occupied 0
    ]

    if shelter-occupied = 1 [
      fd 1; ignore the shelter since is occupied
      report 1 ;avoiding the shelter
    ]

    if shelter-occupied = 0 [
      ; verify conditions to enter
      ; shelter entrance rule = (energy < 500  && experience < 25 )? true: false
      if energy < 500 and experience < 25 [
        rt -90 ; go to the shelter
        report 1
      ]

      if energy >= 500 or experience >= 25 [
        ;show "i have more energy or experience that is allowed to enter in the shelter on the left - avoiding :("
        fd 1; ignoring the shelter
        report 1
      ]
    ]

  ]

    if [pcolor] of patch-right-and-ahead 90 1 = blue [
    ; shelter occupied? cannot enter  (report 1 avoid it )
    let shelter-occupied 1

    if count expert-agent-on patch-right-and-ahead 90 1 = 0 [
      set shelter-occupied 0
    ]

    if shelter-occupied = 1 [
      fd 1; ignore the shelter since is occupied
      report 1 ;avoiding the shelter
    ]

    if shelter-occupied = 0 [
      ; verify conditions to enter
      ; shelter entrance rule = (energy < 500  && experience < 25 )? true: false
      if energy < 500 and experience < 25 [
        rt 90 ; go to the shelter
        report 1
      ]

      if energy >= 500 or experience >= 25 [
        ;show "i have more energy or experience that is allowed to enter in the shelter on the right - avoiding :("
        fd 1; ignoring the shelter
        report 1
      ]
    ]

  ]

  report 0; the agent isnt in any shelter and didnt perceived one
end

to-report handle-expert-agent-food
  ; verify if the agent made a move
  let action-available 1

  ; main agent memory
  let virtual-energy energy
  let virtual-green-food-eaten total-green-food-eaten
  let virtual-yellow-food-eaten total-yellow-food-eaten

  ; memory used to count the food eaten to give experience to the agent
  let virtual-total-yellow-food-eaten-temp total-yellow-food-eaten-temp
  let virtual-total-green-food-eaten-temp total-green-food-eaten-temp

  ; is food in the agent position? eat it
  ask patch-here[
    (
      ifelse
      pcolor = green [
        set virtual-energy virtual-energy + 10
        set virtual-green-food-eaten virtual-green-food-eaten + 1
        set virtual-total-green-food-eaten-temp virtual-total-green-food-eaten-temp + 1
        set pcolor black
        set action-available 0
      ]
      pcolor = yellow [
        set virtual-energy virtual-energy + 5
        set virtual-yellow-food-eaten virtual-yellow-food-eaten  + 1
        set virtual-total-yellow-food-eaten-temp virtual-total-yellow-food-eaten-temp  + 1
        set pcolor black
        set action-available 0
      ]
    )
  ]

  ; update agent memory
  set energy virtual-energy
  set total-green-food-eaten virtual-green-food-eaten
  set total-yellow-food-eaten virtual-yellow-food-eaten

  ; verify if we need to give experince to the agent
  (
    ifelse
    total-green-food-eaten-temp = 10 [
      set experience experience + 2
      set total-green-food-eaten-temp 0
    ]
    total-yellow-food-eaten-temp = 10 [
      set experience experience + 1
      set total-yellow-food-eaten-temp 0
    ]
  )

  if action-available = 0 [
    fd 1
    report nobody
  ]

  ; if the agent is available for a move perceive foward left and right
  if [pcolor] of patch-ahead 1 = green [
    fd 1
    report nobody
  ]

  if [pcolor] of patch-ahead 1 = yellow [
    fd 1
    report nobody
  ]

  if [pcolor] of patch-left-and-ahead 90 1 = yellow [
    rt -90
    report nobody
  ]

  if [pcolor] of patch-left-and-ahead 90 1 = green [
    rt -90
    report nobody
  ]

  if [pcolor] of patch-right-and-ahead 90 1 = yellow [
    rt 90
    report nobody
  ]

  if [pcolor] of patch-right-and-ahead 90 1 = green [
    rt 90
    report nobody
  ]

  ; if there isnt any perception on foward, left and right move foward
  fd 1
  report nobody
end

to handle-expert-agent
  ask expert-agent
  [
    let action-available 1

    ; perception foward, left and right (shelters,food,traps and agents)
    ; actions: foward, rotate 90 right or rotate 90 left
    ; action = energy -1

    let action-agent-interaction handle-expert-agent-interaction

    ; trap action logic
    let action-trap handle-expert-agent-trap
    if action-trap = 1 [
      set action-available 0
    ]
    if action-trap = 2 [
      set action-available 0
      die
    ]

    ; verify if the agent have a action available to verify the shelter
    if action-available = 1 [
      let action-shelter handle-expert-agent-shelter
      if action-shelter = 1 [
        set action-available 0
      ]
    ]

    ; verify if there's any action available to eat food
    if action-available = 1 [
      let action-food handle-expert-agent-food
    ]

    set energy energy - 1
  ]
end

to handle-restore-food

  let current-yellow-food  (count patches with [pcolor = yellow])
  let current-green-food (count patches with [pcolor = green])

  ;show restore-food

  (ifelse

    restore-food = 1 [

      set restore-food 0
      if(current-green-food < total-green-food)[
        ;restore green food
        let add-food total-green-food - current-green-food

        ask n-of add-food patches with [pcolor = black][
          set pcolor green
        ]
      ]


      if(current-yellow-food < total-yellow-food)[
        ;restore yellow food
        let add-food total-yellow-food - current-yellow-food

        ask n-of add-food patches with [pcolor = black][
          set pcolor yellow
        ]
      ]

    ]

    restore-food = 0 [
      set restore-food 1
    ]
  )

end

to handle-restore-shelters
  ask n-of total-shelters-destroyed patches with [pcolor = 35][
    set pcolor blue
  ]
  set total-shelters-destroyed 0
end


to go; main tick function called in the interface
  handle-basic-agent
  handle-expert-agent
  handle-restore-food
  handle-restore-shelters

  ask turtles with [energy <= 0] [
    show "i died because i run out of energy :("
    die
  ] ; Energy level reach zero , die.
  if count turtles = 0 [stop]     ; Stops when agents reach zero
  if ticks > 1000 [stop]
  tick
  ;go ; uncomment this line to be recursive and dont interate the actions by click
end


; ==================================
; handle iterations procedures ends here
; ==================================
@#$#@#$#@
GRAPHICS-WINDOW
808
10
1245
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
377
378
801
411
Setup
Setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
19
10
191
43
n-basic-agent
n-basic-agent
0
50
18.0
1
1
NIL
HORIZONTAL

SLIDER
20
51
192
84
n-expert-agent
n-expert-agent
0
100
18.0
1
1
NIL
HORIZONTAL

SLIDER
21
107
260
140
green-food-percentage
green-food-percentage
0
15
15.0
1
1
NIL
HORIZONTAL

SLIDER
22
143
260
176
yellow-food-percentage
yellow-food-percentage
0
5
5.0
0.1
1
NIL
HORIZONTAL

SLIDER
22
216
261
249
n-shelter
n-shelter
0
10
9.0
1
1
NIL
HORIZONTAL

SLIDER
22
180
261
213
trap-percentage
trap-percentage
0
2
0.7
0.1
1
NIL
HORIZONTAL

BUTTON
377
417
802
450
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
377
12
800
267
Agents lifetime
lifetime in ticks
total agents
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"basic agents" 1.0 0 -2064490 true "" "plot count basic-agent"
"expert agents" 1.0 0 -13345367 true "" "plot count expert-agent"

SLIDER
22
319
341
352
basic-agent-camouflage-percentage
basic-agent-camouflage-percentage
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
23
279
275
312
expert-kill-basic-min-energy
expert-kill-basic-min-energy
0
500
101.0
1
1
NIL
HORIZONTAL

MONITOR
377
275
556
320
Total Expert Agents Alive
count expert-agent
17
1
11

MONITOR
631
274
801
319
Total Basic Agents Alive
count basic-agent
17
1
11

MONITOR
376
328
568
373
total-green-food rendered
total-green-food
17
1
11

MONITOR
616
326
801
371
total-yellow-food rendered
total-yellow-food
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="upgraded-model-default" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count basic-agent</metric>
    <metric>count expert-agent</metric>
    <enumeratedValueSet variable="yellow-food-percentage">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-shelter">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="expert-kill-basic-min-energy">
      <value value="101"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-basic-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-expert-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-food-percentage">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basic-agent-camouflage-percentage">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-percentage">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="upgraded-model-plus-basic-agent-50" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count basic-agent</metric>
    <metric>count expert-agent</metric>
    <enumeratedValueSet variable="yellow-food-percentage">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-shelter">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="expert-kill-basic-min-energy">
      <value value="101"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-basic-agent">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-expert-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-food-percentage">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basic-agent-camouflage-percentage">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-percentage">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="upgraded-model-plus-shelter-10" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count basic-agent</metric>
    <metric>count expert-agent</metric>
    <enumeratedValueSet variable="yellow-food-percentage">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-shelter">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="expert-kill-basic-min-energy">
      <value value="101"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-basic-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-expert-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-food-percentage">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basic-agent-camouflage-percentage">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-percentage">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="upgraded-model-plus-basic-min-energy-300" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count basic-agent</metric>
    <metric>count expert-agent</metric>
    <enumeratedValueSet variable="yellow-food-percentage">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-shelter">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="expert-kill-basic-min-energy">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-basic-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-expert-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-food-percentage">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basic-agent-camouflage-percentage">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-percentage">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="upgraded-model-less-basic-min-energy-0" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count basic-agent</metric>
    <metric>count expert-agent</metric>
    <enumeratedValueSet variable="yellow-food-percentage">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-shelter">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="expert-kill-basic-min-energy">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-basic-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-expert-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-food-percentage">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basic-agent-camouflage-percentage">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-percentage">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="upgraded-model-less-min-energy-50-plus-camouflage-85" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count basic-agent</metric>
    <metric>count expert-agent</metric>
    <enumeratedValueSet variable="yellow-food-percentage">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-shelter">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="expert-kill-basic-min-energy">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-basic-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-expert-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-food-percentage">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basic-agent-camouflage-percentage">
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-percentage">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="upgraded-model-less-min-energy-30-plus-camouflage-90" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count basic-agent</metric>
    <metric>count expert-agent</metric>
    <enumeratedValueSet variable="yellow-food-percentage">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-shelter">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="expert-kill-basic-min-energy">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-basic-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-expert-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-food-percentage">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basic-agent-camouflage-percentage">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-percentage">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="upgraded-model-less-min-energy-30-plus-camouflage-100" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count basic-agent</metric>
    <metric>count expert-agent</metric>
    <enumeratedValueSet variable="yellow-food-percentage">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-shelter">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="expert-kill-basic-min-energy">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-basic-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-expert-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-food-percentage">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basic-agent-camouflage-percentage">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-percentage">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="upgraded-model-less-min-energy-30-plus-camouflage-100-plus-shelter-10" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count basic-agent</metric>
    <metric>count expert-agent</metric>
    <enumeratedValueSet variable="yellow-food-percentage">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-shelter">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="expert-kill-basic-min-energy">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-basic-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-expert-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-food-percentage">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basic-agent-camouflage-percentage">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-percentage">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="upgraded-model-less-min-energy-30-plus-camouflage-100-plus-shelter-10-less-agents-10" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count basic-agent</metric>
    <metric>count expert-agent</metric>
    <enumeratedValueSet variable="yellow-food-percentage">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-shelter">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="expert-kill-basic-min-energy">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-basic-agent">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-expert-agent">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-food-percentage">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basic-agent-camouflage-percentage">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-percentage">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="upgraded-model-less-min-energy-30-plus-camouflage-100-plus-shelter-10-less-agents-5" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count basic-agent</metric>
    <metric>count expert-agent</metric>
    <enumeratedValueSet variable="yellow-food-percentage">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-shelter">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="expert-kill-basic-min-energy">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-basic-agent">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-expert-agent">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-food-percentage">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basic-agent-camouflage-percentage">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-percentage">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="upgraded-model-plus-yellow-food" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count basic-agent</metric>
    <metric>count expert-agent</metric>
    <enumeratedValueSet variable="yellow-food-percentage">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-shelter">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="expert-kill-basic-min-energy">
      <value value="101"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-basic-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-expert-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-food-percentage">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basic-agent-camouflage-percentage">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-percentage">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="upgraded-model-plus-yellow-food-plus-shelters-10" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count basic-agent</metric>
    <metric>count expert-agent</metric>
    <enumeratedValueSet variable="yellow-food-percentage">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-shelter">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="expert-kill-basic-min-energy">
      <value value="101"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-basic-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-expert-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-food-percentage">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basic-agent-camouflage-percentage">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-percentage">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="upgraded-model-less-min-energy-30-plus-camouflage-100-plus-shelter-10-less-agents-10-plus-yellow-food-5.0" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count basic-agent</metric>
    <metric>count expert-agent</metric>
    <enumeratedValueSet variable="yellow-food-percentage">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-shelter">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="expert-kill-basic-min-energy">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-basic-agent">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-expert-agent">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-food-percentage">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basic-agent-camouflage-percentage">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-percentage">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="upgraded-model-less-trap-percentage-0.0" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count basic-agent</metric>
    <metric>count expert-agent</metric>
    <enumeratedValueSet variable="yellow-food-percentage">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-shelter">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="expert-kill-basic-min-energy">
      <value value="101"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-basic-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-expert-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-food-percentage">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basic-agent-camouflage-percentage">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-percentage">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="upgraded-model-less-trap-percentage-0.0-plus-camouflage-100" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count basic-agent</metric>
    <metric>count expert-agent</metric>
    <enumeratedValueSet variable="yellow-food-percentage">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-shelter">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="expert-kill-basic-min-energy">
      <value value="101"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-basic-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-expert-agent">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-food-percentage">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="basic-agent-camouflage-percentage">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trap-percentage">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
