-- mmorpg dice game

-- global variables
outcomes = {"ambush", "down", "run", "fire", "rally", "advance"}
outcome_colors = {8, 9, 10, 11, 12, 7}
zones = {"safe", "combat", "resource"}
zone_colors = {6, 2, 14}
players = {}
log = {}
log_scroll = 0
max_log_lines = 5
turn_timer = 0
max_turn_time = 30
winner = nil
game_state = "start"  -- states: "start", "play", "gameover"

-- game initialization
function _init()
  players = create_players()
end

-- game update loop
function _update()
  if game_state == "start" then
    handle_start_screen()
  elseif game_state == "gameover" then
    handle_gameover_screen()
  else
    handle_gameplay()
  end
end

-- draw function
function _draw()
  cls()
  if game_state == "start" then
    draw_start_screen()
  elseif game_state == "gameover" then
    draw_game_over()
  else
    draw_gameplay()
  end
end

-- create players
function create_players()
  local new_players = {}
  for i = 1, 12 do
    add(new_players, {
      id = i,
      zone = flr(rnd(3)) + 1,
      dice = {roll_dice(), roll_dice()},
      hp = 3,
      score = 0
    })
  end
  return new_players
end

-- handle start screen logic
function handle_start_screen()
  if any_key_pressed() then
    game_state = "play"
    _init()  -- initialize the game
  end
end

-- handle game over screen logic
function handle_gameover_screen()
  if any_key_pressed() then
    game_state = "start"  -- restart the game
  end
end

-- handle gameplay logic
function handle_gameplay()
  turn_timer += 1
  if turn_timer >= max_turn_time or btnp(4) and not (btn(0) or btn(1)) then
    resolve_round()
    turn_timer = 0
  end

  -- scroll log
  if btnp(0) then log_scroll = max(0, log_scroll - 1)
  elseif btnp(1) then log_scroll = min(#log - max_log_lines, log_scroll + 1)
  end
end

-- draw start screen
function draw_start_screen()
  cls(1)
  print("ヌあ⬆️ヤま◆ mmorpg dice clash", 16, 20, 7)
  print("each player rolls 2 dice:", 10, 36, 6)
  display_outcomes()
  display_zones()
  print("press any key to begin", 24, 118, 7)
end

-- display outcomes
function display_outcomes()
  for i, outcome in ipairs(outcomes) do
    print("- "..outcome, 20, 46 + i * 6, outcome_colors[i])
  end
end

-- display zones
function display_zones()
  print("zones: safe, combat, resource", 10, 94, 6)
  print("players interact in zones.", 10, 102, 6)
end

-- draw game over screen
function draw_game_over()
  cls(0)
  print("ユか◆▒ game over ユか◆▒", 32, 40, 7)
  if winner then
    print("player "..winner.id.." wins!", 28, 60, 11)
  else
    print("no winner!", 40, 60, 8)
  end
  print("press any key to restart", 16, 90, 6)
end

-- draw gameplay (zones, players, ui, log)
function draw_gameplay()
  draw_zones()
  draw_players()
  draw_ui()
  draw_log()
end

-- draw zones
function draw_zones()
  for i = 1, #zones do
    rectfill(0, (i - 1) * 40, 127, i * 40 - 1, zone_colors[i])
    print(zones[i], 2, (i - 1) * 40 + 2, 7)
  end
end

-- draw players
function draw_players()
  for p in all(players) do
    local x = 10 + (p.id - 1) % 6 * 20
    local y = (p.zone - 1) * 40 + 20
    local color = (p.hp <= 0) and 8 or 7  -- 8 = gray or red for dead, 7 = default for alive

    circfill(x, y, 5, color)
    print(p.hp, x - 2, y - 8, 8)

    -- display dice
    for i, d in ipairs(p.dice) do
      print(outcomes[d], x - 16 + i * 16, y + 8, outcome_colors[d])
    end
  end
end

-- draw ui (time, controls, etc.)
function draw_ui()
  print("time: "..(max_turn_time - turn_timer), 2, 2, 7)
  print("press 🅾️ to roll", 80, 2, 7)
end

-- draw event log (scrollable)
function draw_log()
  local log_y = 112
  print("events: ヌ●…ヌ●★", 2, log_y, 7)
  for i = 0, max_log_lines - 1 do
    local log_index = #log - log_scroll - (max_log_lines - 1) + i
    if log_index >= 1 and log[log_index] then
      print(log[log_index], 2, log_y + 6 + i * 6, 6)
    end
  end
end

-- resolve round (apply dice outcomes)
function resolve_round()
  for p in all(players) do
    for d in all(p.dice) do
      apply_outcome(p, d)
    end
    p.dice = {roll_dice(), roll_dice()}
  end

  -- remove players whose hp <= 0
  players = filter(players, function(p) return p.hp > 0 end)

  -- check for game over (last player standing)
  if #players == 1 then
    winner = players[1]
    game_state = "gameover"
  end
end

-- apply dice outcome
function apply_outcome(p, d)
  if d == 1 then
    handle_ambush(p)
  elseif d == 2 then
    handle_down(p)
  elseif d == 3 then
    handle_run(p)
  elseif d == 4 then
    handle_fire(p)
  elseif d == 5 then
    handle_rally(p)
  elseif d == 6 then
    handle_advance(p)
  end
end

-- handle ambush outcome
function handle_ambush(p)
  local t = random_target(p.zone, p)
  if t then
    t.hp -= 1
    log_event("p"..p.id.." ambushed p"..t.id.."!")
    if t.hp <= 0 then log_event("p"..t.id.." has died!") end
  end
end

-- handle down outcome
function handle_down(p)
  local t = random_target(p.zone, p)
  if t then
    t.dice[1] = roll_dice()
    log_event("p"..p.id.." suppressed p"..t.id.."!")
  end
end

-- handle run outcome
function handle_run(p)
  local old = p.zone
  p.zone = flr(rnd(3)) + 1
  log_event("p"..p.id.." ran from "..zones[old].." to "..zones[p.zone].."!")
end

-- handle fire outcome
function handle_fire(p)
  local hit = false
  for o in all(players) do
    if o.zone == p.zone and o != p then
      o.hp -= 1
      log_event("p"..p.id.." fired at p"..o.id.."!")
      if o.hp <= 0 then log_event("p"..o.id.." has died!") end
      hit = true
    end
  end
  if not hit then log_event("p"..p.id.." fired but missed.") end
end

-- handle rally outcome
function handle_rally(p)
  if p.hp < 3 then
    p.hp += 1
    log_event("p"..p.id.." rallied and healed.")
  else
    log_event("p"..p.id.." rallied but was full hp.")
  end
end

-- handle advance outcome
function handle_advance(p)
  p.score += 1
  log_event("p"..p.id.." advanced and scored.")
end

-- roll dice (random number)
function roll_dice()
  return flr(rnd(6)) + 1
end

-- select random target in the same zone (exclude current player)
function random_target(zone, exclude)
  local options = {}
  for o in all(players) do
    if o.zone == zone and o != exclude then
      add(options, o)
    end
  end
  if #options > 0 then
    return options[flr(rnd(#options)) + 1]
  end
end

-- log event (for display)
function log_event(event)
  add(log, event)
  if #log > max_log_lines then
    del(log, log[1])
  end
end

-- check if any key is pressed
function any_key_pressed()
  return btnp(0) or btnp(1) or btnp(2) or btnp(3) or btnp(4) or btnp(5) or btnp(6) or btnp(7)
end

-- filter function to remove dead players
function filter(tbl, func)
  local result = {}
  for i, v in ipairs(tbl) do
    if func(v) then
      add(result, v)
    end
  end
  return result
end
