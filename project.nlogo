 __includes ["labs.nls"]

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
globals [
  UNKNOWN
  GROUND
  WALL
  ZOMBIE_SQUARE
  OCCUPIED

  KILLS
  EPISODES
  ORIGINAL_POSITIONS
]

;;;
;;;  Set global variables' values
;;;
to set-globals
  ;;; Map variables
  set UNKNOWN 0
  set GROUND 1
  set WALL 2
  set ZOMBIE_SQUARE 3
  set OCCUPIED 4

  ;;; Global variables
  set KILLS 0
  set Human-Strategy "BDI"
  set ORIGINAL_POSITIONS []
end

;;;
;;;  Declare two types of turtles
;;;
breed [ humans human ]
breed [ zombies zombie ]

;;;
;;;  Declare cells' properties
;;;

;;;
;;;  Agent's variables
;;;
humans-own [
  field-of-depth

  world-map
  current-position

  prey

  desire
  intention
  plan
  last-action
]

zombies-own[
  last-action
]

patches-own[
  kind
]

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
  resize-world MAP_WIDTH * -1 MAP_WIDTH MAP_WIDTH * -1 MAP_WIDTH
  set-globals
  setup-patches
  setup-turtles
  setup-obstacles
  init-agents
  reset-ticks
end

;;;
;;;  Setup all the agents. Create humans ands 4 crates
;;;
to setup-turtles
  let human-count HUMAN_INITIAL_COUNT
  let i 0
  let xxcor (MAP_WIDTH * -1) + 1
  let yycor MAP_WIDTH - 1

  set-default-shape humans "person"
  set-default-shape zombies "person"

  create-humans human-count
  while [ i < human-count ]
  [
    ;; set human
    ask turtle i [ init-human
      let pos random-map-position
      ifelse (RANDOM_SPAWNS)
      [ set xcor item 0 pos
        set ycor item 1 pos ]
      [ set xcor xxcor
        set ycor yycor - ( i mod (MAP_WIDTH * 2 - 1)) ]
      set current-position build-position xcor ycor
      set heading 90
      set size 1
      set ORIGINAL_POSITIONS lput build-position [xcor] of human i [ycor] of human i ORIGINAL_POSITIONS
      ]
    set i i + 1
  ]

  spawn-zombies ZOMBIE_INITIAL_COUNT
end

to setup-patches
  ;; Build the wall
  let i 0
  let j 0

  ;; Build the floor
  ask patches [
    set kind GROUND
    set pcolor green + 8
  ]

  set i MAP_WIDTH
  while [i >= 0]
  [
    if (i = 0 or i = MAP_WIDTH)
    [ build-vertical-wall i ]

    ; Top walls
    ask patch i MAP_WIDTH
    [ set kind WALL
      set pcolor black ]
    ask patch (i * -1) MAP_WIDTH
    [ set kind WALL
      set pcolor black ]

    ; Bottom walls
    ask patch i (MAP_WIDTH * -1)
    [ set kind WALL
      set pcolor black ]
    ask patch (i * -1) (MAP_WIDTH  * -1)
    [ set kind WALL
      set pcolor black ]

    set i i - 1
  ]
end

to setup-obstacles
    ; Build obstacles
  if (OBSTACLES)
  [
    let nobstacles 5 + random (2 * MAP_WIDTH)

    while [ nobstacles >= 0 ]
    [
      let random-position random-map-position
      ask patch item 0 random-position item 1 random-position
        [ set kind WALL
          set pcolor black ]
        set nobstacles nobstacles - 1
    ]
  ]
end


to build-vertical-wall [ ii ]
  let coord 0
  let k 0

  ifelse (ii > 0 )
  [ set coord MAP_WIDTH ]
  [ set coord (MAP_WIDTH * -1) ]

  set k MAP_WIDTH

  while [k >= 0]
  [
    ask patch coord k
    [ set kind WALL
      set pcolor black ]

    ask patch coord (k * -1)
    [ set kind WALL
      set pcolor black ]

    set k k - 1
  ]
end

;;;
;;;  Count the number of humans
;;;
to-report head-count
  report count humans
end

to-report zombie-count
  report count zombies
end

to-report kills-count
  report KILLS
end

to-report episodes-count
  report EPISODES
end

;;;
;;;  Step up the simulation
;;;
to go
  tick

  ;; the zombies action
  ask zombies [
      zombie-loop
  ]

  ;; the humans action
  ask humans [
      human-loop
  ]

  ;; Check if the goal was achieved, is everyone dead yet?
  if (not any? zombies)
    [
      ifelse (not EPISODIC)
      [ stop ]
      [
         ; reset the humans coord
         let gi 0
         foreach ORIGINAL_POSITIONS
         [
           ask human gi [
             set current-position ?1
             set xcor item 0 ?1
             set ycor item 1 ?1
             set heading 90
             set desire 0
             set intention 0
             set plan []
             set last-action ""
             set prey 0
           ]
           set gi gi + 1
         ]
         ; spawn zombies again
         spawn-zombies ZOMBIE_INITIAL_COUNT
      ]
    ]

  if ticks >= TICK_LIMIT
    [ stop ]
end

;;;
;;;  =================================================================
;;;
;;;      SPAWNERS DEFINITION
;;;
;;;  =================================================================

;;;
;;;  Creates a new zombie
;;;
to spawn-zombies [ number ]
  while [number > 0]
  [
    create-zombies 1
    [
      ;; set the zombie
      init-zombie
    ]
    set number number - 1
  ]
end

;;;
;;;  Turn a human into a zombie
;;;
to human-to-zombie [ human ]
  let x [xcor] of human
  let y [ycor] of human
  ask human [die]
  hatch-zombies 1[
    init-zombie
    set xcor x
    set ycor y
  ]
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
;;;      Inteligent agent capable of surviving
;;;
;;;  =================================================================
to init-human
  set field-of-depth SIGHT_RANGE
  set color white
  set world-map build-new-map
  fill-map
  set plan build-empty-plan
  set last-action ""
end

to human-loop

  ; Remove zombies from current vision to avoid outdated data
  forget-zombies

  ; Gets input from world, updates map and tells everyone what he saw
  let vision patches in-radius field-of-depth
  update-status vision
  send-message-to-others list "update" vision

  if (Human-Strategy = "Reactive")
  [ human-reactive ]
  if (Human-Strategy = "BDI")
  [ human-BDI ]
  if (Human-Strategy = "Learning")
  [ human-learning ]

end

;;;
;;; Reactive Architecture
;;;

to human-reactive
  ifelse ( any? zombies-on patch-ahead 1 )
  [ kill-zombie-ahead]
  [ human-move-randomly ]
end


;;;
;;; BDI Architecture
;;;

to human-BDI

  ifelse not (empty-plan? plan or intention-succeeded? intention or impossible-intention? intention)
  [
    execute-plan-action
  ]
  [
    ;; Check the human's options
    set desire BDI-desire
    set intention BDI-filter
    set plan build-plan-for-intention intention

    ;TODO

  ]
end

; generates the human's current desire
to-report BDI-desire
  ifelse (not (member? (word "" ZOMBIE_SQUARE) world-map))
  [ report "search" ]
  [ report "hunt" ]
end

to-report BDI-filter
  let pos-or 0

  ifelse desire = "search"
  [
    set pos-or random-map-corner
    report build-intention desire build-position item 0 pos-or item 1 pos-or (random 4 * 90)
  ]
  [
    if desire = "hunt" [
      set pos-or find-zombie-position
      set prey pos-or
      let assignment assign-positions pos-or
      if (assignment = false)
        [ set desire "search"
          set pos-or random-map-corner
          report build-intention desire build-position item 0 pos-or item 1 pos-or (random 4 * 90)
        ]
      report intention
    ]
  ]
  report build-empty-intention
end

to-report build-plan-for-intention [iintention]
  let new-plan 0
  set new-plan build-empty-plan

  if  not empty-intention? iintention
  [
    set new-plan build-path-plan current-position item 1 iintention
    set new-plan add-instruction-to-plan new-plan build-instruction-find-heading item 2 iintention

    if get-intention-desire iintention = "search"
    [
      set new-plan add-instruction-to-plan new-plan build-instruction-search
    ]
    if get-intention-desire iintention = "hunt"
    [
      set new-plan add-instruction-to-plan new-plan build-instruction-hunt
    ]
  ]
  report new-plan
end

;;;
;;; Learning Architecture
;;;

to human-learning
  ;TODO human learning algorithm here
end

;;;
;;; ----------------------------
;;;    Comunication procedures
;;; ----------------------------
;;;

;;;
;;;  Send a message to all humans
;;;
to send-message [ msg ]
  ask humans [ handle-message msg ]
end

;;;
;;;  Send a message to other humans
;;;
to send-message-to-others [ msg ]
  ask other humans [ handle-message msg ]
end

;;;  Send a message to a specified human
to send-message-to-human [id-human msg]
  ask turtle id-human [handle-message msg]
end

;;; Handle a new received message
to handle-message [msg]
  let action item 0 msg

  if(action = "update")
  [
    update-status item 1 msg
  ]
  if(action = "assignment")
  [
    set prey item 3 msg
    set desire "hunt"
    set intention build-intention desire item 1 msg item 2 msg
    set plan build-plan-for-intention intention
  ]
end

;;;
;;;  =================================================================
;;;
;;;      MAP
;;;
;;;  =================================================================

;;;  Build a new map with UNKNOWN in all positions
to-report build-new-map
  let m 0

  set m ""

  let mapsize (MAP_WIDTH * 2) + 1

  repeat mapsize * mapsize
    [ set m word m UNKNOWN ]

  report m
end

;;; Writhes in the internal map given mtype for given position
to write-map [pos mtype]
  let x 0
  let y 0

  set x item 0 pos
  set y item 1 pos

  set world-map replace-item ((x + MAP_WIDTH) + (y + MAP_WIDTH) * (MAP_WIDTH * 2 + 1)) world-map (word "" mtype)
end

;;; Returns the internal map's state for given position
to-report read-map-position [pos]
  let x 0
  let y 0
  let mapsize 0

  set x item 0 pos
  set y item 1 pos
  set mapsize (2 * MAP_WIDTH) + 1

  report item ((x + MAP_WIDTH) + (y + MAP_WIDTH) * mapsize) world-map
end

;;; Initializes internal map with walls and Unknown
to fill-map
  let patch_type 0
  foreach sort patches
  [
    ifelse ([kind]of ?1 = WALL)
    [ set patch_type WALL ]
    [ set patch_type UNKNOWN ]
    write-map ( build-position [pxcor] of ?1 [pycor] of ?1 ) patch_type
  ]
end

;;; Removes all zombies from internal map
to forget-zombies
  if (member? (word "" ZOMBIE_SQUARE) world-map)
[  let index position (word "" ZOMBIE_SQUARE) world-map
  set world-map replace-item index world-map (word "" UNKNOWN) ]
end

to-report random-map-corner
  let rmci random 2
  let rmcj random 2

  if (rmci = 0)
  [ set rmci -1 ]
  if (rmcj = 0)
  [ set rmcj -1 ]

  report build-position ((rmci * (MAP_WIDTH - 2)) * random 2) ((rmcj * (MAP_WIDTH - 2)) * random 2)
end

to-report random-map-position
  let rmpx (random (MAP_WIDTH * 2 + 1) - MAP_WIDTH)
  let rmpy (random (MAP_WIDTH * 2 + 1) - MAP_WIDTH)
  while [ any? turtles-on patch rmpx rmpy or [kind] of patch rmpx rmpy = WALL ]
  [
    set rmpx (random (MAP_WIDTH * 2 + 1) - MAP_WIDTH)
    set rmpy (random (MAP_WIDTH * 2 + 1) - MAP_WIDTH)
  ]

  report build-position rmpx rmpy
end

;;;
;;; Distributes adjacent positions to other humans
;;;
to-report assign-positions [ zpos ]
  let surrounding-squares all-adjacent-positions zpos

  foreach surrounding-squares
  [
    if ([kind] of patch-position ?1 = WALL)
    [ set surrounding-squares remove ?1 surrounding-squares ]
  ]

  foreach surrounding-squares
  [
    if (any? humans-on patch-position ?1)
    [
      let aux-human one-of humans-on patch-position ?1
      send-message-to-human ([who] of aux-human) (list "assignment" ?1 (calculate-heading ?1 zpos) zpos)
      set surrounding-squares remove ?1 surrounding-squares
    ]
  ]

  if (empty? surrounding-squares)
  [ report false ]

  let team sort n-of (length surrounding-squares - 1) other humans

  foreach but-first surrounding-squares
  [
    ;todo take distance into account here, attribute closest square to human
    let aux-team-member first team
    send-message-to-human ([who] of aux-team-member) (list "assignment" ?1 (calculate-heading ?1 zpos) zpos)
    set surrounding-squares remove ?1 surrounding-squares
    set team but-first team
  ]

  if (empty? surrounding-squares)
  [ report false ]

  let a-p-target-pos first surrounding-squares
  send-message-to-human who (list "assignment" a-p-target-pos (calculate-heading a-p-target-pos zpos) zpos)

  report true
end

;;;
;;;  A colision between humans occured whihe executing the plan
;;;
to collided
  if (any? humans-on patch-ahead 1)
  [ set plan build-plan-for-intention intention ]
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
  set size 1
  set color black
  set heading 0
  set xcor random MAP_WIDTH
  set ycor random MAP_WIDTH
end

to zombie-loop
  zombie-move-randomly
end

;;;
;;; ------------------------
;;;  Actuators
;;; ------------------------
;;;

;;; Human actuators

; faces a random direction or moves ahead
to human-move-randomly
  ifelse (random 2 = 0) [ rotate-random ]
  [human-move-ahead]
end

; moves 1 patch ahead. cant walk into walls
to human-move-ahead
  let ahead (patch-ahead 1)
  ;; check if the cell is free
  if (free-cell?)
  [ fd 1
    set current-position position-ahead
    set last-action "move-ahead"
  ]
end

; Kills the zombie right ahead. Fails if none ahead
to kill-zombie-ahead

  ; face the zombie. WITH CORRECT PLANNING THIS WONT BE NEEDED! TODO
  if (any? zombies in-radius 1)
  [ face one-of zombies in-radius 1 ]

  let kzzombie zombies-on patch-ahead 1

  if (any? kzzombie)
  [
    let kzzpos build-position first [xcor] of kzzombie first [ycor] of kzzombie
    let kzfree-cells free-adjacent-positions kzzpos

    if (empty? kzfree-cells)
    [
      ask kzzombie [die]
      set KILLS KILLS + 1

      if (RESPAWN)
      [
        hatch-zombies 1 [
          init-zombie
          let kzapos random-map-position
          set xcor item 0 kzapos
          set ycor item 1 kzapos
        ]
      ]
    ]
  ]
end

;;; Zombie actuators

; faces a random direction and goes ahead
to zombie-move-randomly
  ifelse (random 2 = 0) [ rotate-random ]
  [ zombie-move-ahead ]
end


;;;  Move the zombie 1 step forward. Zombies cant walk on Bunker
to zombie-move-ahead
  let ahead (patch-ahead 1)
  ;; check if the cell is free
  if ([kind] of ahead != WALL and not any? turtles-on patch-ahead 1)
  [ fd 1
    set last-action "move-ahead"]
end

;;; General actuators

;;;
;;;  Rotate turtle to a random direction
;;;
to rotate-random
  ifelse (random 2 = 0)
  [ rotate-left ]
  [ rotate-right ]
end

;;;
;;; ------------------------
;;;   Sensors
;;; ------------------------
;;;

;;; Human sensors

;;; Find the position for a zombie in the internal map. False if there is none
to-report find-zombie-position
  let fzpi MAP_WIDTH * -1
  let fzpj MAP_WIDTH * -1
  let fzpsquare 0
  let fzpflag true

  while [ fzpflag ]
  [
    set fzpsquare read-map-position build-position fzpi fzpj

    ifelse (fzpsquare = word "" ZOMBIE_SQUARE)
    [ set fzpflag false ]
    [
      set fzpi fzpi + 1

      if (fzpi = MAP_WIDTH)
      [
        set fzpi MAP_WIDTH * -1
        set fzpj fzpj + 1
      ]

      if (fzpj = MAP_WIDTH) [report false]
    ]
  ]
  report build-position fzpi fzpj
end

;;; Writes what the human sees in the internal map
to update-status [ vision ]
  let x ""
  let y ""
  let patch-content ""
  let position-list ""

  foreach sort vision
  [
    if ([pxcor] of ?1 = MAP_WIDTH or [pycor] of ?1 = MAP_WIDTH)
    [ ask ?1 [set vision other vision] ]
  ]

  foreach sort vision
  [
    write-map list [pxcor] of ?1 [pycor] of ?1 [kind] of ?1
  ]

  if (any? turtles-on vision)
    [
      foreach (sort humans-on vision)
      [ write-map build-position [xcor] of ?1 [ycor] of ?1 OCCUPIED ]

      foreach (sort zombies-on vision)
      [ write-map build-position [xcor] of ?1 [ycor] of ?1 ZOMBIE_SQUARE ]
    ]
end

;;; Reports true if there is a zombie ahead
to-report zombies-ahead?
  let zhzombies zombies-on patch-ahead 1
  ifelse (any? zhzombies)
  [ report true ]
  [ report false ]
end
@#$#@#$#@
GRAPHICS-WINDOW
441
69
751
400
7
7
20.0
1
10
1
1
1
0
0
0
1
-7
7
-7
7
1
1
1
ticks
30.0

BUTTON
124
26
189
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
194
26
263
59
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
268
26
336
59
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

CHOOSER
54
312
227
357
Human-Strategy
Human-Strategy
"Reactive" "BDI" "Learning"
1

SLIDER
54
204
226
237
HUMAN_INITIAL_COUNT
HUMAN_INITIAL_COUNT
4
12
4
1
1
NIL
HORIZONTAL

SLIDER
252
205
425
238
ZOMBIE_INITIAL_COUNT
ZOMBIE_INITIAL_COUNT
1
5
1
1
1
NIL
HORIZONTAL

SLIDER
55
101
227
134
TICK_LIMIT
TICK_LIMIT
500
2000
1035
1
1
NIL
HORIZONTAL

SLIDER
231
101
403
134
MAP_WIDTH
MAP_WIDTH
5
15
7
1
1
NIL
HORIZONTAL

SLIDER
54
240
226
273
SIGHT_RANGE
SIGHT_RANGE
1
2 * MAP_WIDTH
3
1
1
NIL
HORIZONTAL

MONITOR
506
21
594
66
Zombies killed
kills-count
17
1
11

SWITCH
54
276
227
309
RANDOM_SPAWNS
RANDOM_SPAWNS
1
1
-1000

SWITCH
278
246
390
279
RESPAWN
RESPAWN
0
1
-1000

TEXTBOX
115
186
265
204
Humans
11
0.0
1

TEXTBOX
312
188
462
206
Zombies\n
11
0.0
1

SWITCH
278
283
391
316
RUN_AWAY
RUN_AWAY
1
1
-1000

SWITCH
115
138
226
171
EPISODIC
EPISODIC
1
1
-1000

TEXTBOX
183
79
333
97
Environment variables
11
0.0
1

SWITCH
230
138
351
171
OBSTACLES
OBSTACLES
1
1
-1000

MONITOR
609
21
703
66
Nº of episodes
episodes-count
17
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
