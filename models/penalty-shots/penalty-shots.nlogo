extensions [rnd]

globals [
  shooter-zone-probabilities
  shot-location
  zone-centroids
  x-width
  y-height
  horizontal-line-count
  saves
  save-percentage
]
turtles-own [
  keeper-location
  keeper-zone-counts  ;; make this consistent! should it be renamed and be global since it's associated with shooter, ie, shot-zone-counts
  keeper-zone-probabilities
]


to setup
  clear-all

  ;; set global statistics
  set-shooter-zone-probabilities
  set y-height (max-pycor - min-pycor)
  set x-width (max-pxcor - min-pxcor)
  set horizontal-line-count zones - (zones / 2 + 1)
  set-zone-centroids
  set saves 0
  set save-percentage  0

  ;; create goal keeper
  crt 1 [
    setxy 0 min-pycor + 2.5
    set shape "person"
    set color blue
    set size 5

    ; initialize keeper stats
    set keeper-zone-counts n-values zones [1]
    set-keeper-zone-probabilities
  ]

  ;; color the goal white
  ask patches [ set pcolor white ]

  ;; draw the keeper zones
  draw-zones

  reset-ticks
end

to go
  ;; recalculate the keeper-zone-probabilities based on shooter's past action
  ask turtles [
    set-keeper-zone-probabilities
  ]

  ;; clear the shot-location red mark!
  ask patches with [pcolor = red] [
    set pcolor white
  ]

  ;; determine where shooter is going to aim for and shoot!
  set-shot-location shooter-zone-probabilities

  ;; move shot to shot-location centroid
  let shooter-zone-centroid item shot-location zone-centroids
  let shot-zone-centroid-x item 0 shooter-zone-centroid
  let shot-zone-centroid-y item 1 shooter-zone-centroid
  ask patch (shot-zone-centroid-x + 1) (shot-zone-centroid-y + 1) ;; offset the centroid by 1 so the turtle and patch can both be visible!
  [ set pcolor red ]

  ;; determine where keeper is going to guess!
  ask turtles [
    set-keeper-location keeper-zone-probabilities
  ]

  ;; move keeper to keeper-location centroid
  ask turtles [
    let keeper-zone-centroid item keeper-location zone-centroids
    let keeper-zone-centroid-x item 0 keeper-zone-centroid
    let keeper-zone-centroid-y item 1 keeper-zone-centroid
    setxy keeper-zone-centroid-x keeper-zone-centroid-y
  ]

  ;; compare location of shot and where keeper is. if they are the same, it is a save!
  ask turtles [
    if shot-location = keeper-location [set saves saves + 1]
    if ticks > 0 [ set save-percentage (saves / ticks) ]
  ]

  ;; update keeper-zone-counts for next iteration
  ask turtles [
    let new-value (item shot-location keeper-zone-counts) + 1 ; Increment the value at the index
    set keeper-zone-counts replace-item shot-location keeper-zone-counts new-value ; Replace the value in the list
  ]

  tick
end

to draw-zones
  draw-vertical-line
  if zones > 2 [ draw-horizontal-lines ]
end

to draw-vertical-line
  let x 0
  let y-start min-pycor
  let y-end max-pycor
  ask patches with [pxcor = x and pycor >= y-start and pycor <= y-end] [
    set pcolor black
  ]
end

to draw-horizontal-lines

  let x-start min-pxcor
  let x-end max-pxcor

  let y-step round (y-height / (horizontal-line-count + 1))

  foreach (range 1 (horizontal-line-count + 1)) [
    [hl] ->
    let y min-pycor + hl * y-step
    ask patches with [pxcor >= x-start and pycor <= x-end and pycor = y]
    [set pcolor black]
  ]
end

to set-shooter-zone-probabilities
  ;; make it an empty list
  let raw-shooter-zone-probabilities []

  ;; give the list a random float for each zone
  foreach range zones [
    [z] ->
    set raw-shooter-zone-probabilities insert-item 0 raw-shooter-zone-probabilities random-float 1
  ]

  ; normalize the list; i.e., make sure it all adds to one
  let sum-of-raw-shooter-zone-probabilities sum raw-shooter-zone-probabilities
  set shooter-zone-probabilities map [value -> value / sum-of-raw-shooter-zone-probabilities] raw-shooter-zone-probabilities

end

;; determine where shooter will shoot by his weighted list of preferences
to set-shot-location [weights]
  let items range zones
  let pairs (map list items weights)
  set shot-location first rnd:weighted-one-of-list pairs [ [p] -> last p ]
end


;; determine where shooter will shoot by his weighted list of preferences
to set-keeper-location [weights]
  let items range zones
  let pairs (map list items weights)
  set keeper-location first rnd:weighted-one-of-list pairs [ [p] -> last p ]
end

to set-keeper-zone-probabilities
  ; turn the counts into a distribution
  let sum-of-keeper-zone-counts sum keeper-zone-counts
  set keeper-zone-probabilities map [value -> value / sum-of-keeper-zone-counts] keeper-zone-counts
end


to set-zone-centroids
  let centroid-x-coords []
  let centroid-y-coords []

  ;; set centroid-x-coords
  ;; the x-cord centroid will always be at 1/4 or at 3/4 of the width because
  ;; 1) I limited the zones to an even count, and 2) there is always a division
  ;; with a single vertical line at 1/2 (or 2/4) of the width
  foreach range zones [
    [z] ->
    let x-quarter-step x-width / 4
    ifelse z < zones / 2
    [set centroid-x-coords lput (min-pxcor + x-quarter-step) centroid-x-coords]
    [set centroid-x-coords lput (min-pxcor + 3 * x-quarter-step) centroid-x-coords]
  ]

  ;; set centroid-y-coords
  ifelse zones = 2
  [
    set centroid-y-coords (list 0 0)
  ]
  [
    let centroid-y-coords-half []
    foreach range ((horizontal-line-count + 1) * 2) [
      [z] ->
      if z mod 2 = 1
      [
        let y-centroid-step int (y-height / ((horizontal-line-count + 1) * 2))
        set centroid-y-coords-half lput (min-pycor + (z) * y-centroid-step) centroid-y-coords-half
      ]
      set centroid-y-coords sentence centroid-y-coords-half centroid-y-coords-half
    ]
  ]
  set zone-centroids (map list centroid-x-coords centroid-y-coords)
end
@#$#@#$#@
GRAPHICS-WINDOW
345
34
1198
472
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-32
32
-16
16
1
1
1
ticks
30.0

BUTTON
57
78
150
126
set up
setup
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
56
19
254
52
zones
zones
2
8
8.0
2
1
NIL
HORIZONTAL

BUTTON
161
80
254
128
go
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

MONITOR
227
207
288
252
Save %
save-percentage * 100
2
1
11

PLOT
16
327
301
517
Save Percentage
shots
save %
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"sv%" 1.0 0 -16777216 true "" "plot save-percentage * 100"
"luck" 1.0 0 -5298144 true "" "plot-pen-reset\nplotxy 0 (100 / zones)\nplotxy plot-x-max (100 / zones)"

MONITOR
128
153
185
198
Goals
ticks - saves
0
1
11

MONITOR
227
154
287
199
Saves
saves
17
1
11

MONITOR
31
151
88
196
Shots
ticks
17
1
11

MONITOR
128
207
185
252
Goal %
100 * (1 - save-percentage)
2
1
11

MONITOR
32
268
288
313
Shooter Zone Probabilities
map [value -> precision (value * 100) 1] shooter-zone-probabilities
2
1
11

@#$#@#$#@
## WHAT IS IT?

This simulation models a penalty shootout in a football match. When a game ends in a tie score but a winner must be declared, such as in a tournament elimination game, then there's a shootout. Each team will select five players and alternate turns at taking penalty kicks. A penalty kick is a one-on-one matchup between a kicker and a goalkeeper. The shot is taken from a distance of 11 meters (~12 feet). At that distance, the goalkeeper has to guess where the ball will be kicked because there's no time to decide based on observation -- it's almost physically impossible. Often the goalkeeper will be briefed by coaches on the tendencies of the kickers to help them guess correctly. Goalkeepers also have tendencies which kickers hope to exploit.

## HOW IT WORKS

In this simulation, there will need to be two agents -- a goalkeeper and a penalty taker. The environment will be the goal face that is divided into zones.


### Goal Face

The goal face is a spatial zone represented by the main interface square and divided into zones of size 2, 4, 6, or 8. The zones are areas of the goal face where kickers aim for and the goalkeeper guesses.

### Goalkeeper

The goalkeeper is represented by a human icon. The goalkeeper starts off with a strategy of guessing each zone with equal chance. For example, if there are 4 zones in the goal face, then the keeper will start off with a strategy of  [ 0.25 0.25 0.25 0.25 ] which represents the probability of guessing one of the four zones.

At each iteration, the goalkeeper will update their guessing strategy based on actual gameplay and where the kicker is actually aiming.

### Kicker

The kicker will have a list of percentages that would relate to their preferred place to kick the ball. In this model, the kicker is initialized with a random strategy. For example, if there are four zones, then a kicker would have a strategy of probabilities [ w, x, y, z] where 0 <= w, x, y, z <= 1 and w + x + y + z = 1.

A kicker is represented by a red dot in the goal face, so it might be accurate to say that the model actually represent a kick location. For talking about the model intuitively, I prefer to say that the agent is a kicker though.

### Iterations

At each iteration, a kicker will "kick" a ball to a zone, while a goalkeeper would "dive" or otherwise move to a location at the goal. The location of the kick and the goalkeeper dive would be determined by their strategy, i.e., their list of zone percentages.

The kicker will keep their random strategy while the goalkeeper updates their strategy based on what the kicker is doing over time.

At each iteration, the goalkeeper will move to the center of a zone. The kick will also be displayed at the center of a zone. If the kick and goalkeeper are at the same zone, then a "save" is recorded. If the kick and goalkeeper are at different zones, then a "goal" is recorded.

After a large amount of timestamps, the strategies converge to a final save and goal percentages. We can compare these final numbers to random chance to determine how effective the goalkeeper is.

## HOW TO USE IT

First, select the amount of zones in the goal face. There is a slider where you can select 2, 4, 6, or 8 zones. Then, click "Set Up"

After selecting and setting up the amount of zones, click the "Go" button to watch the simulation. To stop the simulation, press "Go" again.

To reset a simulation, first make sure the simulation is stopped (press "Go" until the simulation stops running). Next, press "Reset" to clear the data and start again.

## THINGS TO NOTICE

More importantly, I added several outputs to keep track of: shots, goals, goal percentage, saves, and save percentage. Goal percentage is defined as goals scored divided by ticks. Save percentage is defined as saves divided by ticks. The sum of goal percentage and save percentage will equal 1 in my simulation. I update the numbers at each iteration.

I also display the kicker's strategy. (Unfortunately, I was unable to display the goalkeeper's strategy. I will have to fix this in a future iteration. I did print out the goalkeeper's strategy, and I can confirm that it does converge to the kicker's strategy over time.)

Finally, the save percentage is displayed over time in a line chart. There is a red line representing random chance. For example, if there are four zones, then a goalkeeper guessing randomly against a random kick will theoretically have a 25% save percentage. If the save percentage is over the red line, then that indicates a save strategy that is better than random chance.


## THINGS TO TRY

You can try setting the number of zones in the goal face. Also, try resetting the model and observing the kicker strategy. Sometimes you will get strategies heavily skewed to certain zones. I found the more skewed a kicker's random strategy is, then the more effective the goalkeeper becomes over time.

## EXTENDING THE MODEL


### Better suited  as a probabilistic model, as is
This is a very early and simplified iteration. It's so simple, in fact, that this would be better run as a probabilistic model in an Excel spreadsheet or as a Python script.

### Adding kickers
Currently the simulation is a goalkeeper vs a single kicker. I have plans to extend this script so that a keeper faces five kickers, to be more realistic.

### Strategy Updates
In the simulation against five kickers, the goalkeeper will keep and update a single strategy against each of the kickers. The keeper will also maintain a single overall strategy that represents all the kickers. Each goalkeeper guess per iteration will be a weighted guess between the individual kicker strategy and the overall strategy. The weights can be adjusted.

The kickers will also update their strategies based on their individual and the group's overall past perfomances.

Also, I would like to addthe ability to either 1) input the strategy percentage lists or 2) have it randomly determined.

### Introducing Skill

Finally, I think it would be a good idea to add skill to the game. In the model's current iteration, the kickers are guaranteed to place the kick where they aim and the goalkeeper is guaranteed to arrive at their intended location. In real life, players aren't able to always complete their intended action.


## NETLOGO FEATURES

I'm quite proud of the geometry (mostly division!) I used to display the zones. Please take a look at the code and see how I generalized dividing the goal face into an even number of zones. (For simplicity, I decided against dividing the goal face into odd numbers of zones)

## RELATED MODELS

I found the NetLogo documentation to be very helpful and thorough. Apart from the models presented in class, I mostly relied on the documentation.

## CREDITS AND REFERENCES

I'd like to link to the github repository, but the instructions say not to include identifiable information!
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
1
@#$#@#$#@
