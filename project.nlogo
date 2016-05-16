;;;
;;;  =================================================================
;;;
;;;      Simulation world definition
;;;
;;;  =================================================================
;;;

;;;
;;;  Global variables and constants
;;;
globals [GROUND WALL BUNKER_FLOOR MARKET_FLOOR SMALL MEDIUM LARGE HUMAN-RESPAWN-TIMER RESPAWN-TIMER ZOMBIE-RESPAWN-TIMER CRATE-RESPAWN-TIMER EMPTY_BACKPACK]

;;;
;;;  Set global variables' values
;;;
to set-globals
  set GROUND 0
  set WALL 1
  set BUNKER_FLOOR 2
  set MARKET_FLOOR 3
  set SMALL 4
  set MEDIUM 5
  set LARGE 6
  set RESPAWN-TIMER 15
  set HUMAN-RESPAWN-TIMER RESPAWN-TIMER
  set ZOMBIE-RESPAWN-TIMER RESPAWN-TIMER
  set CRATE-RESPAWN-TIMER RESPAWN-TIMER
end

;;;
;;;  Declare two types of turtles
;;;
breed [ humans human ]
breed [ zombies zombie ]
breed [ crates crate]

;;;
;;;  Declare cells' properties
;;;
patches-own [kind floor-type]

;;;
;;;  The crates have a size property and humans have a backpack
;;;
crates-own [crate-size]
humans-own [backpack]

;;;
;;;  Reset the simulation
;;;
to reset
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  ;;__clear-all-and-reset-ticks
  clear-all
  reset-ticks
  set-globals
  setup-patches
  setup-turtles
  init-agents
end

;;;
;;;  Setup all the agents. Create humans ands 4 crates
;;;
to setup-turtles
  let human-count 15
  let i 0
  create-humans human-count
  set-default-shape humans "person"
  set-default-shape zombies "person"
  set-default-shape crates "box"

  while [ i < human-count ]
  [
    ;; set human
    ask turtle i [set color blue]
    ask turtle i [set xcor (-2 + random 5) ]
    ask turtle i [set ycor (-2 + random 5) ]
    set i i + 1
  ]
end

;;;
;;;  Setup the environment. Populate the room.
;;;
to setup-market [ setup-market-size i ]
    let setup-x-market 8
    let setup-y-market 8

    let j 0

    while [ j < setup-market-size]
      [
        ;top left
        ask patch (-1 * (setup-x-market + j)) (setup-y-market + i) [set pcolor gray + 3]
        ask patch (-1 * (setup-x-market + j)) (setup-y-market + i) [set kind MARKET_FLOOR]

        ;top right
        ask patch (setup-x-market + j) (setup-y-market + i) [set pcolor gray + 3]
        ask patch (setup-x-market + j) (setup-y-market + i) [set kind MARKET_FLOOR]

        ;bottom left
        ask patch (-1 * (setup-x-market + j)) ((setup-y-market + i) * -1) [set pcolor gray + 3]
        ask patch (-1 * (setup-x-market + j)) ((setup-y-market + i) * -1) [set kind MARKET_FLOOR]

        ;bottom right
        ask patch (setup-x-market + j) ((setup-y-market + i) * -1) [set pcolor gray + 3]
        ask patch (setup-x-market + j) ((setup-y-market + i) * -1) [set kind MARKET_FLOOR]
        set j j + 1
      ]
end

to setup-patches
  ;; Build the floor
  ask patches [
    set kind GROUND
    set pcolor green + 6 ]

  ask patch 0 0 [set pcolor white]

  ;; Build the wall
  foreach [-15 -14 -13 -12 -11 -10 -9 -8 -7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15]
  [ ask patch ? -15 [set pcolor black]
    ask patch ? -15 [set kind WALL]
    ask patch ? 15 [set pcolor black]
    ask patch ? 15 [set kind WALL]
    ask patch -15 ? [set pcolor black]
    ask patch -15 ? [set kind WALL]
    ask patch 15 ? [set pcolor black]
    ask patch 15 ? [set kind WALL]]

  ;; Build the markets


  let i 0
  let setup-market-size 5
  while [ i < setup-market-size]
  [
    setup-market setup-market-size i
    set i i + 1
  ]

  ;; Build the bunker
  foreach [-2 -1 0 1 2]
  [
    ask patch ? -2 [set pcolor yellow]
    ask patch ? -2 [set kind BUNKER_FLOOR]
    ask patch ? -1 [set pcolor yellow]
    ask patch ? -1 [set kind BUNKER_FLOOR]
    ask patch ? 0 [set pcolor yellow]
    ask patch ? 0 [set kind BUNKER_FLOOR]
    ask patch ? 1 [set pcolor yellow]
    ask patch ? 1 [set kind BUNKER_FLOOR]
    ask patch ? 2 [set pcolor yellow]
    ask patch ? 2 [set kind BUNKER_FLOOR]
  ]

end

;;;
;;;  Count the number of humans
;;;
to-report head-count
  report count humans
end

to-report zombie-count
  report count humans
end

;;;
;;;  Return number of humans in the bunket
;;;
to-report initial-positions

end

;;;
;;;  Step up the simulation
;;;
to go
  tick
  ;; the humans action
  ask humans [
      human-loop
  ]
    ;; the zombies action
  ask zombies [
      zombie-loop
  ]

  spawn-human
  spawn-zombie
  spawn-crate

  ;; Check if the goal was achieved, is everyone dead yet?
  if head-count = 0
    [ stop ]
end

;;;
;;;  =================================================================
;;;
;;;      SPAWNERS DEFINITION
;;;
;;;  =================================================================

;;;
;;;  Creates a new crate
;;;  Green boxes are small, blue are medium, red are large
;;;
to spawn-crate
  let coord-list [-10 10]
  if CRATE-RESPAWN-TIMER <= 0 [
    create-crates 1 [
      ;; set crates variables
      let i random 100
      if i > 90 and i < 100
      [ set crate-size LARGE
        set color red]
      if i > 70 and i < 90
      [ set crate-size MEDIUM
        set color blue ]
      if i > 0 and i < 60
      [ set crate-size SMALL
        set color green ]
      set size 0.7
      set heading 0
      set xcor one-of coord-list + random 5 - 2
      set ycor one-of coord-list + random 5 - 2
      set CRATE-RESPAWN-TIMER random RESPAWN-TIMER
    ]
  ]
  set CRATE-RESPAWN-TIMER CRATE-RESPAWN-TIMER - 1
end

;;;
;;;  Creates a new human
;;;
to spawn-human
  if HUMAN-RESPAWN-TIMER <= 0 [
    create-humans 1 [
      ;; set human
      set color blue
      set xcor (-2 + random 5)
      set ycor (-2 + random 5)
      set HUMAN-RESPAWN-TIMER random RESPAWN-TIMER
      set backpack EMPTY_BACKPACK
    ]
  ]
  set HUMAN-RESPAWN-TIMER HUMAN-RESPAWN-TIMER - 1
end

;;;
;;;  Creates a new zombie
;;;
to spawn-zombie
  let coord-list [-13 13]
  if ZOMBIE-RESPAWN-TIMER <= 0 [
    create-zombies 1 [
      ;; set the zombie
      set color black
      set xcor one-of coord-list
      set ycor one-of coord-list
      set ZOMBIE-RESPAWN-TIMER random RESPAWN-TIMER
    ]
  ]
  set ZOMBIE-RESPAWN-TIMER ZOMBIE-RESPAWN-TIMER - 1
end


;;;
;;;  Move the crate to the humans' current position
;;;
to move-crate
  let r-xcor xcor
  let r-ycor ycor
  ask backpack [set xcor r-xcor]
  ask backpack [set ycor r-ycor]
end

;;;
;;;  =================================================================
;;;
;;;      AGENT DEFINITION
;;;
;;;  =================================================================

to init-agents
ask humans [init-human]
ask zombies [init-zombie]
end

;;;
;;;  =================================================================
;;;
;;;      THE HUMAN
;;;
;;;  =================================================================
to init-human
end

to human-loop
end

;;;
;;;  =================================================================
;;;
;;;      THE ZOMBIE
;;;
;;;      Reactive agent who chases humans
;;;
;;;  =================================================================
to init-zombie
end

to zombie-loop
  ifelse ( human-nearby? )
  [
    print "GET HIM!!"
    chase-human
  ]
  [ move-randomly ]
end

to chase-human
  zombie-move-ahead
end

to move-randomly
  rotate-random
  zombie-move-ahead
end



;;; ============================================================================================

;;;
;;; ------------------------
;;;   Actuators
;;; ------------------------
;;;

;;;
;;;  Move the zombie 1 step forward. Zombies cant walk on Bunker
;;;
to zombie-move-ahead
  let ahead (patch-ahead 1)
  ;; check if the cell is free
  if ([kind] of ahead != BUNKER_FLOOR) and ([kind] of ahead != WALL)
  [ fd 1 ]
end

;;;
;;;  Allow the human to grab the crate
;;;
to grab-crate
  let crate crate-ahead
  ; Check if there is a crate on the cell ahead
  if crate != nobody
    [ set backpack crate
      move-crate ]
end

;;;
;;;  Rotate turtle to a random direction
;;;
to rotate-random
  ifelse (random 2 = 0)
  [ rotate-left ]
  [ rotate-right ]
end

;;;
;;;  Rotate turtle to left
;;;
to rotate-left
  lt 90
end

;;;
;;;  Rotate turtle to right
;;;
to rotate-right
  rt 90
end

;;;
;;; ------------------------
;;;   Sensors
;;; ------------------------
;;;

;;;
;;;  Check if there are humans around
;;;
to-report human-nearby?
    report any? humans-on (patch-ahead 5)
end


;;;
;;;  Check if the human is carrying a food crate
;;;
to-report carrying-crate?
  report not (backpack = EMPTY_BACKPACK)
end

;;;
;;;  Check if the cell ahead contains a crate
;;;
to-report cell-has-crate?
  report any? crates-on (patch-ahead 1)
end

;;;
;;;  Returns the crate in front of the human
;;;
to-report crate-ahead
  report one-of crates-on patch-ahead 1
end

;;;
;;;  Check if the cell ahead is floor (which means not a wall, not a bunker nor market)
;;;
to-report free-cell?
  let frente (patch-ahead 1)
  report ([kind] of frente = GROUND)
end

;;;
;;;  Check if the cell ahead is a bunker
;;;
to-report bunker-cell?
  report ([kind] of (patch-ahead 1) = BUNKER_FLOOR)
end

;;;
;;;  Check if the cell ahead is a market floor
;;;
to-report market-cell?
  report ([kind] of (patch-ahead 1) = MARKET_FLOOR)
end
@#$#@#$#@
GRAPHICS-WINDOW
321
10
951
661
15
15
20.0
1
10
1
1
1
0
1
1
1
-15
15
-15
15
0
0
1
ticks
30.0

BUTTON
29
26
94
59
NIL
Reset
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
130
27
199
60
Run
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

BUTTON
230
27
298
60
Step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
38
226
124
271
Total humans
head-count
0
1
11

MONITOR
132
226
216
271
Total zombies
zombie-count
0
1
11

@#$#@#$#@
## ABSTRACT TYPES


### intention
An 'intention' is a list with 3 elements <desire, position, heading> ( desire is a string, position is internal abstract type 'position' and the heading is a numerical degree between 0 and 360.
####Basic reporters:
- build-empty-intention
- build-intention [ddesire pposition hheading]
- get-intention-desire [iintention]
- get-intention-position [iintention]
- get-intention-heading [iintention]
- empty-intention? [iintention]

### plan-instruction
A 'plan-instruction' is a single instruction that is part of a plan. It contains a list of 2 elements <type,value> (the type of the instruction as a string and a value, when it is required). There are four instructions: grab, drop, find an adjacent position and find heading.
####Basic eporters:
- build-instruction [ttype vvalue]
- get-instruction-type [iinstruction]
- get-instruction-value [iinstruction]
- build-instruction-find-adjacent-position [aadjacent-position]
- build-instruction-find-heading [hheading]
- build-instruction-drop []
- build-instruction-grab []
- instruction-find-adjacent-position? [iinstruction]
- instruction-find-heading? [iinstruction]
- instruction-drop? [iinstruction]
- instruction-grab? [iinstruction]

### plan
A 'plan' is composed by 'plan-insctruction' elements. It is initialized as an empty list and instructions are then added or removed.

####Basic reporters:
- build-empty-plan
- add-instruction-to-plan [pplan iinstruction]
- remove-plan-first-instruction [pplan]
- get-plan-first-instruction [pplan]
- empty-plan? [pplan]
- build-path-plan [posi posf]

####Extra reporters:
- execute-plan-action


### position
A 'position' is a list of two elements <x-cor,y-cor> (the x coordinate and the y coordinate).
####Basic reporters:
- build-position [x y]
- xcor-of-position [pposition]
- ycor-of-position [pposition]
- equal-positions? [pos1 pos2]
- position-ahead

####Extra reporters:
- find-path [intialPos FinalPos]
- free-adjacent-positions [pos]
- adjacent-positions-of-type [pos ttype]

### shelf-info
A 'shelf-info' contains information about a shelf cell and uses a list of 3 elements <position,color,occupied?> (the shelf cell position, the shelf color and a boolean referring the state of the shelf).
####Basic reporters:
- build-shelf-info [pos ccolor occupied?]
- shelf-info-position [sshelf]
- shelf-info-color [sshelf]
- shelf-info-occupied [sshelf]

####Extra reporters:
- find-shelf-position [pos]
- find-shelf-of-color [ppcolor poccupied?]

### ramp-info
A 'ramp-info' contains information about a ramp cell and uses a list of 2 elements <position,occupied?> (the ramp cell position and a boolean referring the state of the ramp).
####Basic reporters:
- build-ramp-info [pos occupied?]
- get-ramp-info-position [rramp]
- get-ramp-info-occupied [rramp]

####Extra reporters:
- find-ramp-on-position [pos]
- find-occupied-ramp

### map
####Basic reporters:
- build-new-map
- write-map [pos mtype]
- read-map-position [pos]

####Extra reporters:
- fill-map
- print-map

## Other reporters

###Comunication
- send-message [msg]
- send-message-to-robot [id-robot msg]

###Auxiliary reporters:
- find-solution [node closed]
- heuristic [node mgoal]
- adjacents [node mobjectivo]
- free-adjacent-positions [pos]

## ACTUATORES:

- move-ahead
- rotate-left
- rotate-right: Rotate turtle to right
- rotate-random: Rotate turtle to a random direction
- grab-box: Allow the robot to put a box on its cargo
- drop-box: Allow the robot to drop the box in its cargo

## SENSORS:

- box-cargo?: Check if the robot is carrying a box
- cargo-box-color: Return the color of the box in robot's cargo or WITHOUT_CARGO otherwise
- box-ahead-color: Return the color of the box ahead
- cell-color: Return the color of the shelf ahead or 0 otherwise
- free-cell?: Check if the cell ahead is floor (which means not a wall, not a shelf nor a ramp) and there are any robot there
- cell-has-box?: Check if the cell ahead contains a box
- shelf-cell?: Check if the cell ahead is a shelf
- ramp-cell?: Check if the cell ahead is a ramp



##REFERENCES:

[Wooldridge02] - Wooldridge, M.; An Introduction to Multiagent Systems; John WIley & Sons, Ltd; 2002
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

ant
true
0
Polygon -7500403 true true 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -7500403 true true 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -7500403 true true 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -7500403 true true 225 66 230 107 159 122 161 127 234 111 236 106
Polygon -7500403 true true 78 58 99 116 139 123 137 128 95 119
Polygon -7500403 true true 48 103 90 147 129 147 130 151 86 151
Polygon -7500403 true true 65 224 92 171 134 160 135 164 95 175
Polygon -7500403 true true 235 222 210 170 163 162 161 166 208 174
Polygon -7500403 true true 249 107 211 147 168 147 168 150 213 150

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bee
true
0
Polygon -1184463 true false 152 149 77 163 67 195 67 211 74 234 85 252 100 264 116 276 134 286 151 300 167 285 182 278 206 260 220 242 226 218 226 195 222 166
Polygon -16777216 true false 150 149 128 151 114 151 98 145 80 122 80 103 81 83 95 67 117 58 141 54 151 53 177 55 195 66 207 82 211 94 211 116 204 139 189 149 171 152
Polygon -7500403 true true 151 54 119 59 96 60 81 50 78 39 87 25 103 18 115 23 121 13 150 1 180 14 189 23 197 17 210 19 222 30 222 44 212 57 192 58
Polygon -16777216 true false 70 185 74 171 223 172 224 186
Polygon -16777216 true false 67 211 71 226 224 226 225 211 67 211
Polygon -16777216 true false 91 257 106 269 195 269 211 255
Line -1 false 144 100 70 87
Line -1 false 70 87 45 87
Line -1 false 45 86 26 97
Line -1 false 26 96 22 115
Line -1 false 22 115 25 130
Line -1 false 26 131 37 141
Line -1 false 37 141 55 144
Line -1 false 55 143 143 101
Line -1 false 141 100 227 138
Line -1 false 227 138 241 137
Line -1 false 241 137 249 129
Line -1 false 249 129 254 110
Line -1 false 253 108 248 97
Line -1 false 249 95 235 82
Line -1 false 235 82 144 100

bird1
false
0
Polygon -7500403 true true 2 6 2 39 270 298 297 298 299 271 187 160 279 75 276 22 100 67 31 0

bird2
false
0
Polygon -7500403 true true 2 4 33 4 298 270 298 298 272 298 155 184 117 289 61 295 61 105 0 43

boat1
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 33 230 157 182 150 169 151 157 156
Polygon -7500403 true true 149 55 88 143 103 139 111 136 117 139 126 145 130 147 139 147 146 146 149 55

boat2
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 157 54 175 79 174 96 185 102 178 112 194 124 196 131 190 139 192 146 211 151 216 154 157 154
Polygon -7500403 true true 150 74 146 91 139 99 143 114 141 123 137 126 131 129 132 139 142 136 126 142 119 147 148 147

boat3
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 37 172 45 188 59 202 79 217 109 220 130 218 147 204 156 158 156 161 142 170 123 170 102 169 88 165 62
Polygon -7500403 true true 149 66 142 78 139 96 141 111 146 139 148 147 110 147 113 131 118 106 126 71

box
true
0
Polygon -7500403 true true 45 255 255 255 255 45 45 45

butterfly1
true
0
Polygon -16777216 true false 151 76 138 91 138 284 150 296 162 286 162 91
Polygon -7500403 true true 164 106 184 79 205 61 236 48 259 53 279 86 287 119 289 158 278 177 256 182 164 181
Polygon -7500403 true true 136 110 119 82 110 71 85 61 59 48 36 56 17 88 6 115 2 147 15 178 134 178
Polygon -7500403 true true 46 181 28 227 50 255 77 273 112 283 135 274 135 180
Polygon -7500403 true true 165 185 254 184 272 224 255 251 236 267 191 283 164 276
Line -7500403 true 167 47 159 82
Line -7500403 true 136 47 145 81
Circle -7500403 true true 165 45 8
Circle -7500403 true true 134 45 6
Circle -7500403 true true 133 44 7
Circle -7500403 true true 133 43 8

circle
false
0
Circle -7500403 true true 35 35 230

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

person
false
0
Circle -7500403 true true 155 20 63
Rectangle -7500403 true true 158 79 217 164
Polygon -7500403 true true 158 81 110 129 131 143 158 109 165 110
Polygon -7500403 true true 216 83 267 123 248 143 215 107
Polygon -7500403 true true 167 163 145 234 183 234 183 163
Polygon -7500403 true true 195 163 195 233 227 233 206 159

sheep
false
15
Rectangle -1 true true 90 75 270 225
Circle -1 true true 15 75 150
Rectangle -16777216 true false 81 225 134 286
Rectangle -16777216 true false 180 225 238 285
Circle -16777216 true false 1 88 92

spacecraft
true
0
Polygon -7500403 true true 150 0 180 135 255 255 225 240 150 180 75 240 45 255 120 135

thin-arrow
true
0
Polygon -7500403 true true 150 0 0 150 120 150 120 293 180 293 180 150 300 150

truck-down
false
0
Polygon -7500403 true true 225 30 225 270 120 270 105 210 60 180 45 30 105 60 105 30
Polygon -8630108 true false 195 75 195 120 240 120 240 75
Polygon -8630108 true false 195 225 195 180 240 180 240 225

truck-left
false
0
Polygon -7500403 true true 120 135 225 135 225 210 75 210 75 165 105 165
Polygon -8630108 true false 90 210 105 225 120 210
Polygon -8630108 true false 180 210 195 225 210 210

truck-right
false
0
Polygon -7500403 true true 180 135 75 135 75 210 225 210 225 165 195 165
Polygon -8630108 true false 210 210 195 225 180 210
Polygon -8630108 true false 120 210 105 225 90 210

turtle
true
0
Polygon -7500403 true true 138 75 162 75 165 105 225 105 225 142 195 135 195 187 225 195 225 225 195 217 195 202 105 202 105 217 75 225 75 195 105 187 105 135 75 142 75 105 135 105

wolf
false
0
Rectangle -7500403 true true 15 105 105 165
Rectangle -7500403 true true 45 90 105 105
Polygon -7500403 true true 60 90 83 44 104 90
Polygon -16777216 true false 67 90 82 59 97 89
Rectangle -1 true false 48 93 59 105
Rectangle -16777216 true false 51 96 55 101
Rectangle -16777216 true false 0 121 15 135
Rectangle -16777216 true false 15 136 60 151
Polygon -1 true false 15 136 23 149 31 136
Polygon -1 true false 30 151 37 136 43 151
Rectangle -7500403 true true 105 120 263 195
Rectangle -7500403 true true 108 195 259 201
Rectangle -7500403 true true 114 201 252 210
Rectangle -7500403 true true 120 210 243 214
Rectangle -7500403 true true 115 114 255 120
Rectangle -7500403 true true 128 108 248 114
Rectangle -7500403 true true 150 105 225 108
Rectangle -7500403 true true 132 214 155 270
Rectangle -7500403 true true 110 260 132 270
Rectangle -7500403 true true 210 214 232 270
Rectangle -7500403 true true 189 260 210 270
Line -7500403 true 263 127 281 155
Line -7500403 true 281 155 281 192

wolf-left
false
3
Polygon -6459832 true true 117 97 91 74 66 74 60 85 36 85 38 92 44 97 62 97 81 117 84 134 92 147 109 152 136 144 174 144 174 103 143 103 134 97
Polygon -6459832 true true 87 80 79 55 76 79
Polygon -6459832 true true 81 75 70 58 73 82
Polygon -6459832 true true 99 131 76 152 76 163 96 182 104 182 109 173 102 167 99 173 87 159 104 140
Polygon -6459832 true true 107 138 107 186 98 190 99 196 112 196 115 190
Polygon -6459832 true true 116 140 114 189 105 137
Rectangle -6459832 true true 109 150 114 192
Rectangle -6459832 true true 111 143 116 191
Polygon -6459832 true true 168 106 184 98 205 98 218 115 218 137 186 164 196 176 195 194 178 195 178 183 188 183 169 164 173 144
Polygon -6459832 true true 207 140 200 163 206 175 207 192 193 189 192 177 198 176 185 150
Polygon -6459832 true true 214 134 203 168 192 148
Polygon -6459832 true true 204 151 203 176 193 148
Polygon -6459832 true true 207 103 221 98 236 101 243 115 243 128 256 142 239 143 233 133 225 115 214 114

wolf-right
false
3
Polygon -6459832 true true 170 127 200 93 231 93 237 103 262 103 261 113 253 119 231 119 215 143 213 160 208 173 189 187 169 190 154 190 126 180 106 171 72 171 73 126 122 126 144 123 159 123
Polygon -6459832 true true 201 99 214 69 215 99
Polygon -6459832 true true 207 98 223 71 220 101
Polygon -6459832 true true 184 172 189 234 203 238 203 246 187 247 180 239 171 180
Polygon -6459832 true true 197 174 204 220 218 224 219 234 201 232 195 225 179 179
Polygon -6459832 true true 78 167 95 187 95 208 79 220 92 234 98 235 100 249 81 246 76 241 61 212 65 195 52 170 45 150 44 128 55 121 69 121 81 135
Polygon -6459832 true true 48 143 58 141
Polygon -6459832 true true 46 136 68 137
Polygon -6459832 true true 45 129 35 142 37 159 53 192 47 210 62 238 80 237
Line -16777216 false 74 237 59 213
Line -16777216 false 59 213 59 212
Line -16777216 false 58 211 67 192
Polygon -6459832 true true 38 138 66 149
Polygon -6459832 true true 46 128 33 120 21 118 11 123 3 138 5 160 13 178 9 192 0 199 20 196 25 179 24 161 25 148 45 140
Polygon -6459832 true true 67 122 96 126 63 144

@#$#@#$#@
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
