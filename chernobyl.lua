
local ffi = require 'ffi'

ffi.cdef[[
    typedef struct
    {
        uint8_t r;
        uint8_t g;
        uint8_t b;
        uint8_t a;
    } color_struct_t;
    typedef void (__cdecl* print_function)(void*, color_struct_t&, const char* text, ...);
]]
local uintptr_t = ffi.typeof("uintptr_t**")
local color_struct_t = ffi.typeof("color_struct_t")

local color_print = (function()local b=function(c,d)c=tostring(c)local e=ffi.cast(uintptr_t,client.create_interface("vstdlib.dll","VEngineCvar007"))local f=ffi.cast("print_function",e[0][25])f(e,color_struct_t(d.r,d.g,d.b,d.a),c)end;return b end)()
local function log(b)color_print("chernobyl \0",color_struct_t(136, 93, 252,255))color_print('~ \0',color_struct_t(136, 93, 252,255))color_print(b,color_struct_t(200,200,200,255))color_print('\n',color_struct_t(200,200,200,0))end
log("private build")

local vector = require 'vector'

local base64 = require 'gamesense/base64'
local clipboard = require 'gamesense/clipboard'

local c_entity = require 'gamesense/entity'
local csgo_weapons = require 'gamesense/csgo_weapons'
local trace = require 'gamesense/trace'
local localize = require 'gamesense/localize'

local http = require 'gamesense/http'
local websockets = require 'gamesense/websockets'

local inspect = require 'gamesense/inspect'

local function DUMMY(...)
    return ...
end

local function contains(list, value)
    for i = 1, #list do
        if list[i] == value then
            return i
        end
    end

    return nil
end

local function round(x)
    return math.floor(x + 0.5)
end

local script = { } do
    script.name = 'chernobyl'
    script.build = 'private'
    script.user = _USER_NAME or 'chernobyl'
end

local color = { } do
    color = ffi.typeof [[
        struct {
            unsigned char r;
            unsigned char g;
            unsigned char b;
            unsigned char a;
        }
    ]]

    local M = { } do
        M.__index = M

        function M:__tostring()
            return string.format(
                '%i, %i, %i, %i',
                self:unpack()
            )
        end

        function M.lerp(a, b, t)
            return color(
                a.r + t * (b.r - a.r),
                a.g + t * (b.g - a.g),
                a.b + t * (b.b - a.b),
                a.a + t * (b.a - a.a)
            )
        end

        function M:unpack()
            return self.r, self.g, self.b, self.a
        end

        function M:clone()
            return color(self:unpack())
        end

        function M:to_hex()
            return string.format(
                '%02x%02x%02x%02x',
                self:unpack()
            )
        end

        function M:hsv(h, s, v)
            local r, g, b

            h = (h % 1.0) * 360
            s = math.max(0, math.min(s, 1))
            v = math.max(0, math.min(v, 1))

            local c = v * s
            local x = c * (1 - math.abs((h / 60) % 2 - 1))
            local m = v - c

            if h < 60 then
                r, g, b = c, x, 0
            elseif h < 120 then
                r, g, b = x, c, 0
            elseif h < 180 then
                r, g, b = 0, c, x
            elseif h < 240 then
                r, g, b = 0, x, c
            elseif h < 300 then
                r, g, b = x, 0, c
            else
                r, g, b = c, 0, x
            end

            self.r = (r + m) * 255
            self.g = (g + m) * 255
            self.b = (b + m) * 255
            self.a = 255

            return self
        end
    end

    ffi.metatype(color, M)
end

local motion do
    motion = { }

    local function linear(t, b, c, d)
        return c * t / d + b
    end

    local function get_deltatime()
        return globals.frametime()
    end

    local function solve(easing_fn, prev, new, clock, duration)
        if clock <= 0 then return new end
        if clock >= duration then return new end

        prev = easing_fn(clock, prev, new - prev, duration)

        if type(prev) == 'number' then
            if math.abs(new - prev) < 0.001 then
                return new
            end

            local remainder = prev % 1.0

            if remainder < 0.001 then
                return math.floor(prev)
            end

            if remainder > 0.999 then
                return math.ceil(prev)
            end
        end

        return prev
    end

    function motion.interp(a, b, t, easing_fn)
        easing_fn = easing_fn or linear

        if type(b) == 'boolean' then
            b = b and 1 or 0
        end

        return solve(easing_fn, a, b, get_deltatime(), t)
    end
end

local utils = { } do
    local GetTimescale = vtable_bind('engine.dll', 'VEngineClient014', 91, 'float(__thiscall*)(void*)')

    function utils.lerp(a, b, t)
        return a + (b - a) * t
    end

    function utils.from_hex(hex)
        hex = string.gsub(hex, '#', '')

        local r = tonumber(string.sub(hex, 1, 2), 16)
        local g = tonumber(string.sub(hex, 3, 4), 16)
        local b = tonumber(string.sub(hex, 5, 6), 16)
        local a = tonumber(string.sub(hex, 7, 8), 16)

        return r, g, b, a or 255
    end

    function utils.to_hex(r, g, b, a)
        return string.format('%02x%02x%02x%02x', r, g, b, a)
    end

    function utils.extrapolate(pos, vel, ticks)
        return pos + vel * (ticks * globals.tickinterval())
    end

    function utils.normalize(x, min, max)
        local d = max - min

        while x < min do
            x = x + d
        end

        while x > max do
            x = x - d
        end

        return x
    end

    function utils.trim(str)
        return str
    end

    function utils.clamp(x, min, max)
        return math.max(min, math.min(x, max))
    end

    function utils.event_callback(event_name, callback, value)
        local fn = value == false
            and client.unset_event_callback
            or client.set_event_callback

        fn(event_name, callback)
    end

    function utils.get_eye_position(ent)
        local origin_x, origin_y, origin_z = entity.get_origin(ent)
        local offset_x, offset_y, offset_z = entity.get_prop(ent, 'm_vecViewOffset')

        if origin_x == nil or offset_x == nil then
            return nil
        end

        local eye_pos_x = origin_x + offset_x
        local eye_pos_y = origin_y + offset_y
        local eye_pos_z = origin_z + offset_z

        return eye_pos_x, eye_pos_y, eye_pos_z
    end

    function utils.get_player_weapons(ent)
        local weapons = { }

        for i = 0, 63 do
            local weapon = entity.get_prop(
                ent, 'm_hMyWeapons', i
            )

            if weapon == nil then
                goto continue
            end

            table.insert(weapons, weapon)
            ::continue::
        end

        return weapons
    end

    function utils.random_int(min, max)
        if min > max then
            min, max = max, min
        end

        return client.random_int(min, max)
    end

    function utils.random_float(min, max)
        if min > max then
            min, max = max, min
        end

        return client.random_float(min, max)
    end

    function utils.get_clock()
        return globals.frametime() / GetTimescale()
    end

    function utils.merge(...)
        local str = ''

        for i = 1, select('#', ...) do
            str = str .. select(i, ...)
        end

        return str
    end

    function utils.normalize_angle(angle)
        while angle > 180 do
            angle = angle - 360
        end

        while angle < -180 do
            angle = angle + 360
        end

        return angle
    end
end

local wrappers = { } do
    function wrappers.linear(t, b, c, d)
        return c * t / d + b
    end

    function wrappers.solve(easing_fn, prev, new, clock, duration)
        if clock <= 0 then
            return new
        end

        if clock >= duration then
            return new
        end

        prev = easing_fn(clock, prev, new - prev, duration)

        if type(prev) == "number" then
            if math.abs(new - prev) < 0.001 then
                return new
            end

            local fmod = prev % 1

            if fmod < 0.001 then
                return math.floor(prev)
            end

            if fmod > 0.999 then
                return math.ceil(prev)
            end
        end

        return prev
    end

    function wrappers.interp(a, b, t, easing_fn)
        easing_fn = easing_fn or wrappers.linear

        if type(b) == "boolean" then
            b = b and 1 or 0
        end

        return wrappers.solve(easing_fn, a, b, utils.get_clock(), t)
    end

    function wrappers.normalize_yaw(yaw)
        return (yaw + 180) % -360 + 180
    end
end

local ilocalize = { } do
    local ConvertAnsiToUnicode = vtable_bind(
        'localize.dll', 'Localize_001', 15, 'int(__thiscall*)(void*, const char *ansi, wchar_t *unicode, int buffer_size)'
    )

    function ilocalize.ansi_to_unicode(ansi, unicode, buffer_size)
        return ConvertAnsiToUnicode(ansi, unicode, buffer_size)
    end
end

local surface = { } do
    local wide = ffi.new 'int[1]'
    local tall = ffi.new 'int[1]'

    local SetColor = vtable_bind('vguimatsurface.dll', 'VGUI_Surface031', 15, 'void(__thiscall*)(void* thisptr, int r, int g, int b, int a)')

    local SetTextFont = vtable_bind('vguimatsurface.dll', 'VGUI_Surface031', 23, 'void(__thiscall*)(void*, unsigned int font_id)')
    local SetTextColor = vtable_bind('vguimatsurface.dll', 'VGUI_Surface031', 25, 'void(__thiscall*)(void*, int r, int g, int b, int a)')
    local SetTextPos = vtable_bind('vguimatsurface.dll', 'VGUI_Surface031', 26, 'void(__thiscall*)(void*, int x, int y)')
    local DrawPrintText = vtable_bind('vguimatsurface.dll', 'VGUI_Surface031', 28, 'void(__thiscall*)(void*, const wchar_t *text, int maxlen, int draw_type)')

    local GetFontTall = vtable_bind('vguimatsurface.dll', 'VGUI_Surface031', 74, 'int(__thiscall*)(void*, unsigned int font)')
    local GetTextSize = vtable_bind('vguimatsurface.dll', 'VGUI_Surface031', 79, 'void(__thiscall*)(void*, unsigned int font, const wchar_t *text, int &wide, int &tall)')

    local DrawFilledRectFade = vtable_bind('vguimatsurface.dll', 'VGUI_Surface031', 123, 'void(__thiscall*)(void*, int x0, int y0, int x1, int y1, unsigned int alpha0, unsigned int alpha1, bool bHorizontal)')

    function surface.text_tall(font)
        return GetFontTall(font)
    end

    function surface.measure_text(font, text)
        local buffer = ffi.new 'wchar_t[2048]'

        ilocalize.ansi_to_unicode(text, buffer, 2048)
        GetTextSize(font, buffer, wide, tall)

        return wide[0], tall[0]
    end

    function surface.text(font, x, y, r, g, b, a, text)
        local len = #text

        if len <= 0 then
            return
        end

        local buffer = ffi.new 'wchar_t[2048]'

        ilocalize.ansi_to_unicode(text, buffer, 2048)

        SetTextFont(font)

        SetTextPos(x, y)
        SetTextColor(r, g, b, a)

        DrawPrintText(buffer, len, 0)
    end

    function surface.fade(x, y, w, h, r0, g0, b0, a0, r1, g1, b1, a1, horizontal)
        SetColor(r0, g0, b0, a0)
        DrawFilledRectFade(x, y, x + w, y + h, 255, 0, horizontal)

        SetColor(r1, g1, b1, a1)
        DrawFilledRectFade(x, y, x + w, y + h, 0, 255, horizontal)
    end
end

local reference = { } do
    reference.ragebot = {
        weapon_type = ui.reference(
            'Rage', 'Weapon type', 'Weapon type'
        ),

        aimbot = {
            enabled = {
                ui.reference('Rage', 'Aimbot', 'Enabled')
            },

            double_tap = {
                ui.reference('Rage', 'Aimbot', 'Double tap')
            },

            target_hitbox = ui.reference(
                'Rage', 'Aimbot', 'Target hitbox'
            ),

            force_body_aim = ui.reference(
                'Rage', 'Aimbot', 'Force body aim'
            ),

            minimum_hit_chance = ui.reference(
                'Rage', 'Aimbot', 'Minimum hit chance'
            ),

            minimum_damage = ui.reference(
                'Rage', 'Aimbot', 'Minimum damage'
            ),

            minimum_damage_override = {
                ui.reference('Rage', 'Aimbot', 'Minimum damage override')
            },

            automatic_scope = ui.reference(
                'Rage', 'Aimbot', 'Automatic scope'
            )
        },

        other = {
            quick_peek_assist = {
                ui.reference('Rage', 'Other', 'Quick peek assist')
            },

            quick_peek_assist_mode = {
                ui.reference('Rage', 'Other', 'Quick peek assist mode')
            },

            quick_peek_assist_distance = ui.reference(
                'Rage', 'Other', 'Quick peek assist distance'
            ),

            duck_peek_assist = ui.reference(
                'Rage', 'Other', 'Duck peek assist'
            )
        }
    }

    reference.antiaim = {
        angles = {
            enabled = ui.reference(
                'AA', 'Anti-aimbot angles', 'Enabled'
            ),

            pitch = {
                ui.reference('AA', 'Anti-aimbot angles', 'Pitch')
            },

            yaw_base = ui.reference(
                'AA', 'Anti-aimbot angles', 'Yaw base'
            ),

            yaw = {
                ui.reference('AA', 'Anti-aimbot angles', 'Yaw')
            },

            yaw_jitter = {
                ui.reference('AA', 'Anti-aimbot angles', 'Yaw jitter')
            },

            body_yaw = {
                ui.reference('AA', 'Anti-aimbot angles', 'Body yaw')
            },

            freestanding_body_yaw = ui.reference(
                'AA', 'Anti-aimbot angles', 'Freestanding body yaw'
            ),

            edge_yaw = ui.reference(
                'AA', 'Anti-aimbot angles', 'Edge yaw'
            ),

            freestanding = {
                ui.reference('AA', 'Anti-aimbot angles', 'Freestanding')
            },

            roll = ui.reference(
                'AA', 'anti-aimbot angles', 'Roll'
            )
        },

        fake_lag = {
            enabled = {
                ui.reference('AA', 'Fake lag', 'Enabled')
            },

            amount = ui.reference(
                'AA', 'Fake lag', 'Amount'
            ),

            variance = ui.reference(
                'AA', 'Fake lag', 'Variance'
            ),

            limit = ui.reference(
                'AA', 'Fake lag', 'Limit'
            ),
        },

        other = {
            slow_motion = {
                ui.reference('AA', 'Other', 'Slow motion')
            },

            on_shot_antiaim = {
                ui.reference('AA', 'Other', 'On shot anti-aim')
            },

            leg_movement = ui.reference(
                'AA', 'Other', 'Leg movement'
            ),

            fake_peek = {
                ui.reference('AA', 'Other', 'Fake peek')
            }
        }
    }

    reference.visuals = {
        effects = {
            remove_scope_overlay = ui.reference(
                'Visuals', 'Effects', 'Remove scope overlay'
            )
        }
    }

    reference.misc = {
        miscellaneous = {
            draw_console_output = ui.reference(
                'Misc', 'Miscellaneous', 'Draw console output'
            ),

            ping_spike = {
                ui.reference('Misc', 'Miscellaneous', 'Ping spike')
            }
        },

        settings = {
            menu_color = ui.reference(
                'Misc', 'Settings', 'Menu color'
            ),

            dpi_scale = ui.reference(
                'Misc', 'Settings', 'DPI scale'
            )
        }
    }

    reference.playerlist = {
        players = ui.reference(
            'Players', 'Players', 'Player list'
        ),

        force_body = ui.reference(
            'Players', 'Adjustments', 'Force body yaw'
        ),

        force_body_value = ui.reference(
            'Players', 'Adjustments', 'Force body yaw value'
        ),

        reset = ui.reference(
            'Players', 'Players', 'Reset all'
        )
    }

    function reference.get_dpi()
        local matched = string.match(
            ui.get(reference.misc.settings.dpi_scale), '(%d+)%%'
        )

        if not matched then
            return 0
        end

        return matched * 0.01
    end

    function reference.get_color(to_hex)
        if to_hex then
            return utils.to_hex(ui.get(reference.misc.settings.menu_color))
        end

        return ui.get(reference.misc.settings.menu_color)
    end

    function reference.get_override_damage()
        return ui.get(reference.ragebot.aimbot.minimum_damage_override[3])
    end

    function reference.get_minimum_damage()
        return ui.get(reference.ragebot.aimbot.minimum_damage)
    end

    function reference.is_freestanding()
        return ui.get(reference.antiaim.angles.freestanding[1])
            and ui.get(reference.antiaim.angles.freestanding[2])
    end

    function reference.is_slow_motion()
        return ui.get(reference.antiaim.other.slow_motion[1])
            and ui.get(reference.antiaim.other.slow_motion[2])
    end

    function reference.is_double_tap_active()
        return ui.get(reference.ragebot.aimbot.double_tap[1])
            and ui.get(reference.ragebot.aimbot.double_tap[2])
    end

    function reference.is_override_minimum_damage()
        return ui.get(reference.ragebot.aimbot.minimum_damage_override[1])
            and ui.get(reference.ragebot.aimbot.minimum_damage_override[2])
    end

    function reference.is_on_shot_antiaim_active()
        return ui.get(reference.antiaim.other.on_shot_antiaim[1])
            and ui.get(reference.antiaim.other.on_shot_antiaim[2])
    end

    function reference.is_duck_peek_assist()
        return ui.get(reference.ragebot.other.duck_peek_assist)
    end

    function reference.is_quick_peek_assist()
        return ui.get(reference.ragebot.other.quick_peek_assist[1])
            and ui.get(reference.ragebot.other.quick_peek_assist[2])
    end
end

local event_system = { } do
    local function find(list, value)
        for i = 1, #list do
            if value == list[i] then
                return i
            end
        end

        return nil
    end

    local EventList = { } do
        EventList.__index = EventList

        function EventList:new()
            return setmetatable({
                list = { },
                count = 0
            }, self)
        end

        function EventList:__len()
            return self.count
        end

        function EventList:set(callback)
            if not find(self.list, callback) then
                self.count = self.count + 1
                table.insert(self.list, callback)
            end

            return self
        end

        function EventList:unset(callback)
            local index = find(self.list, callback)

            if index ~= nil then
                self.count = self.count - 1
                table.remove(self.list, index)
            end

            return self
        end

        function EventList:fire(...)
            local list = self.list

            for i = 1, #list do
                list[i](...)
            end

            return self
        end
    end

    local EventBus = { } do
        local function __index(list, k)
            local value = rawget(list, k)

            if value == nil then
                value = EventList:new()
                rawset(list, k, value)
            end

            return value
        end

        function EventBus:new()
            return setmetatable({ }, {
                __index = __index
            })
        end
    end

    function event_system:new()
        return EventBus:new()
    end
end

local ui_callback = { } do
    local lookup = { }

    function ui_callback.set(item, callback, force_call)
        if lookup[item] == nil then
            local list = { }

            -- wtf is that
            ui.set_callback(item, function()
                for i = 1, #list do
                    list[i](item)
                end
            end)

            lookup[item] = list
        end

        local index = contains(lookup[item])

        if index == nil then
            table.insert(lookup[item], callback)
        end

        if force_call then
            callback(item)
        end

        return item
    end

    function ui_callback.unset(item, callback)
        local list = lookup[item]

        if list == nil then
            return
        end

        local index = contains(list, callback)

        if index ~= nil then
            table.remove(list, index)
        end

        return item
    end
end

local theme_controller = { } do
    local function tohex(r, g, b, a)
        return string.format(
            '%02x%02x%02x%02x',
            r, g, b, a or 255
        )
    end

    local invokers = { }

    local menu_color = ui.reference(
        'Misc', 'Settings', 'Menu color'
    )

    local hex = tohex(ui.get(menu_color))

    local Wrapper = { } do
        Wrapper.__index = Wrapper

        function Wrapper:__call()
            local repl = string.format(
                '\a%s%%1\a%s', hex, 'FFFFFFC8'
            )

            local result = string.gsub(
                self.text, '${(.-)}', repl
            )

            return result
        end

        function Wrapper:new(text)
            return setmetatable({
                text = text
            }, self)
        end
    end

    local function table_pack(...)
        local result = { }

        for i = 1, select('#', ...) do
            result[i] = select(i, ...)
        end

        return result
    end

    local function update_invoker(invoker)
        local args = invoker.args

        invoker.item:set(invoker.callback(
            unpack(args, 1, table.maxn(args))
        ))
    end

    function theme_controller.wrap(text)
        return Wrapper:new(text)
    end

    function theme_controller.update()
        for i = 1, #invokers do
            update_invoker(invokers[i])
        end
    end

    function theme_controller.push(item, callback, ...)
        local invoker = {
            item = item,
            args = table_pack(...),
            callback = callback
        }

        update_invoker(invoker)
        table.insert(invokers, invoker)
    end

    local callbacks do
        local function on_menu_color(item)
            hex = tohex(ui.get(item))
            theme_controller.update()
        end

        ui_callback.set(menu_color, on_menu_color)
    end
end

local ragebot = { } do
    local item_data = { }

    local ref_weapon_type = ui.reference(
        'Rage', 'Weapon type', 'Weapon type'
    )

    local e_hotkey_mode = {
        [0] = 'Always on',
        [1] = 'On hotkey',
        [2] = 'Toggle',
        [3] = 'Off hotkey'
    }

    local function get_value(item)
        local type = ui.type(item)
        local value = { ui.get(item) }

        if type == 'hotkey' then
            local mode = e_hotkey_mode[value[2]]
            local keycode = value[3] or 0

            return { mode, keycode }
        end

        return value
    end

    function ragebot.set(item, ...)
        local weapon_type = ui.get(ref_weapon_type)

        if item_data[item] == nil then
            item_data[item] = { }
        end

        local data = item_data[item]

        if data[weapon_type] == nil then
            data[weapon_type] = {
                type = weapon_type,
                value = get_value(item)
            }
        end

        ui.set(item, ...)
    end

    function ragebot.unset(item)
        local data = item_data[item]

        if data == nil then
            return
        end

        local weapon_type = ui.get(ref_weapon_type)

        for k, v in pairs(data) do
            ui.set(ref_weapon_type, v.type)
            ui.set(item, unpack(v.value))

            data[k] = nil
        end

        ui.set(ref_weapon_type, weapon_type)
        item_data[item] = nil
    end
end

local override = { } do
    local item_data = { }

    local e_hotkey_mode = {
        [0] = 'Always on',
        [1] = 'On hotkey',
        [2] = 'Toggle',
        [3] = 'Off hotkey'
    }

    local function get_value(item)
        local type = ui.type(item)
        local value = { ui.get(item) }

        if type == 'hotkey' then
            local mode = e_hotkey_mode[value[2]]
            local keycode = value[3] or 0

            return { mode, keycode }
        end

        return value
    end

    function override.get(item)
        local value = item_data[item]

        if value == nil then
            return nil
        end

        return unpack(value)
    end

    function override.set(item, ...)
        if item_data[item] == nil then
            item_data[item] = get_value(item)
        end

        ui.set(item, ...)
    end

    function override.unset(item)
        local value = item_data[item]

        if value == nil then
            return
        end

        ui.set(item, unpack(value))
        item_data[item] = nil
    end
end

local logging = { } do
    local SCRIPT_NAME = script.name

    local SOUND_SUCCESS = 'ui\\beepclear.wav'
    local SOUND_FAILURE = 'resource\\warning.wav'

    local play = cvar.play

    local function display_tag(r, g, b)
        local text = string.format(
            '[%s]',
            SCRIPT_NAME
        )

        client.color_log(r, g, b, text, ' \0')
    end

    function logging.log(msg)
        display_tag(240, 240, 240)
        client.color_log(255, 255, 255, msg)
    end

    function logging.success(msg)
        display_tag(reference.get_color())

        client.color_log(255, 255, 255, msg)
        play:invoke_callback(SOUND_SUCCESS)
    end

    function logging.error(msg)
        display_tag(250, 50, 75)

        client.color_log(255, 255, 255, msg)
        play:invoke_callback(SOUND_FAILURE)
    end
end

local localdb = { } do
    local BASE64_KEY = '41IwhiXV5v3eaJfgk6SrW0ROKolCMYEUcGBPmb9xzu2HZLjDFys8dpntTQNqA7+/='

    local PATH = '.'
    local FILE = PATH .. '\\chernobyl_db.dat'

    local store = { }

    local function read_file()
        return readfile(FILE)
    end

    local function write_file(str)
        writefile(FILE, str)
    end

    local function encode_data(data)
        local ok, result = pcall(
            json.stringify, data
        )

        if not ok then
            return false, result
        end

        ok, result = pcall(
            base64.encode, result, BASE64_KEY
        )

        if not ok then
            return false, result
        end

        return true, result
    end

    local function decode_data(data)
        local ok, result = pcall(
            base64.decode, data, BASE64_KEY
        )

        if not ok then
            return false, result
        end

        ok, result = pcall(
            json.parse, result
        )

        if not ok then
            return false, result
        end

        return true, result
    end

    local function write_storage(data)
        local ok, result = encode_data(data)

        if not ok then
            logging.error(
                'Unable to encode data'
            )

            return false
        end

        write_file(result)

        return true
    end

    local function parse_storage()
        local content = read_file()

        -- if can't read file, create
        -- new one with empty database
        if content == nil then
            if not write_storage { } then
                logging.log 'Unable to create db'
            end

            return { }
        end

        local ok, result = decode_data(content)

        if not ok then
            logging.error 'Unable to decode db'
            logging.log 'Trying to flush db'

            if not write_storage { } then
                logging.error 'Unable to flush db'
            end

            return { }
        end

        return result
    end

    local M = { } do
        function M:__index(key)
            return store[key]
        end

        function M:__newindex(key, value)
            store[key] = value
            write_storage(store)
        end
    end

    store = parse_storage()
    setmetatable(localdb, M)
end

local config_system = { } do
    local BASE64_KEY = 'bjW9MagJsut5xDz36Hvl74nC8Eoy0GIUVX2NLQepckFfrBYOhRZKAwmSqidP1T+/='

	local HOTKEY_MODE = {
        [0] = 'Always on',
        [1] = 'On hotkey',
        [2] = 'Toggle',
        [3] = 'Off hotkey'
    }

    local item_list = { }
    local item_data = { }

    local function get_item_value(item)
        if item.type == 'hotkey' then
            local _, mode, key = item:get()

            return { HOTKEY_MODE[mode], key or 0 }
        end

        return { item:get() }
    end

    local function get_key_values(arr)
        local list = { }

        if arr ~= nil then
            for i = 1, #arr do
                list[arr[i]] = i
            end
        end

        return list
    end

    function config_system.push(tab, name, item)
        if item_data[tab] == nil then
            item_data[tab] = { }
        end

        local data = {
            tab = tab,
            name = name,
            item = item
        }

        if item_data[tab][name] ~= nil then
            client.error_log(string.format(
                'config collision: [ %s, %s ]',
                tab, name
            ))
        end

        item_data[tab][name] = item
        table.insert(item_list, data)

        return item
    end

    function config_system.encode(data)
        local ok, result = pcall(
            json.stringify, data
        )

        if not ok then
            return false, result
        end

        ok, result = pcall(
            base64.encode,
            result,
            BASE64_KEY
        )

        if not ok then
            return false, result
        end

        return true, string.format(
            'chernobyl_%s_', result
        )
    end

    function config_system.decode(str)
        local data = str:match(
            '%chernobyl%_(.-)_'
        )

        if data == nil then
            return false, 'Invalid config'
        end

        local ok, result = pcall(
            base64.decode,
            data,
            BASE64_KEY
        )

        if not ok then
            return false, result
        end

        ok, result = pcall(
            json.parse, result
        )

        if not ok then
            return false, result
        end

        return true, result
    end

    function config_system.import(data, categories)
        if data == nil then
            return false, 'config is empty'
        end

        local keys = get_key_values(categories)

        for k, v in pairs(data) do
            if categories ~= nil and keys[k] == nil then
                goto continue
            end

            local items = item_data[k]

            if items == nil then
                goto continue
            end

            for m, n in pairs(v) do
                local item = items[m]

                if item ~= nil then
                    pcall(item.set, item, unpack(n))
                end
            end

            ::continue::
        end

        return true, nil
    end

    function config_system.export(categories)
        local list = { }

        local keys = get_key_values(categories)

        for k, v in pairs(item_data) do
            if categories ~= nil and keys[k] == nil then
                goto continue
            end

            local values = { }

            for m, n in pairs(v) do
                values[m] = get_item_value(n)
            end

            list[k] = values

            ::continue::
        end

        return list
    end
end

local menu = { } do
    local event_bus = event_system:new()

    local Item = { } do
        Item.__index = Item

        local function pack(ok, ...)
            if not ok then
                return nil
            end

            return ...
        end

        local function get_value_array(ref)
            return { pack(pcall(ui.get, ref)) }
        end

        local function get_key_values(arr)
            local list = { }

            for i = 1, #arr do
                list[arr[i]] = i
            end

            return list
        end

        local function update_item_values(item, initial)
            local value = get_value_array(item.ref)

            item.value = value

            if initial then
                item.default = value
            end

            if item.type == 'multiselect' then
                item.key_values = get_key_values(unpack(value))
            end
        end

        function Item:new(ref)
            return setmetatable({
                ref = ref,
                type = nil,

                list = { },
                value = { },
                default = { },
                key_values = { },

                callbacks = { }
            }, self)
        end

        function Item:init(...)
            local function callback()
                update_item_values(self, false)
                self:fire_events()

                event_bus.item_changed:fire(self)
            end

            self.type = ui.type(self.ref)

            local can_have_callback = (
                self.type ~= 'label' and
                self.type ~= 'unknown'
            )

            if can_have_callback then
                update_item_values(self, true)
                pcall(ui.set_callback, self.ref, callback)
            end

            if self.type == 'multiselect' or self.type == 'list' then
                self.list = select(4, ...)
            end

            if self.type == 'button' then
                local fn = select(4, ...)

                if fn ~= nil then
                    self:set_callback(fn)
                end
            end

            event_bus.item_init:fire(self)
        end

        function Item:get(key)
            local have_update_callback = (
                self.type ~= 'hotkey' and
                self.type ~= 'textbox' and
                self.type ~= 'unknown'
            )

            if not have_update_callback then
                return ui.get(self.ref)
            end

            if key ~= nil then
                return self.key_values[key] ~= nil
            end

            return unpack(self.value)
        end

        function Item:set(...)
            ui.set(self.ref, ...)
            update_item_values(self, false)
        end

        function Item:update(...)
            ui.update(self.ref, ...)
        end

        function Item:reset()
            pcall(ui.set, self.ref, unpack(self.default))
        end

        function Item:set_enabled(value)
            return ui.set_enabled(self.ref, value)
        end

        function Item:set_visible(value)
            return ui.set_visible(self.ref, value)
        end

        function Item:set_callback(callback, force_call)
            local index = contains(self.callbacks, callback)

            if index == nil then
                table.insert(self.callbacks, callback)
            end

            if force_call then
                callback(self)
            end

            return self
        end

        function Item:unset_callback(callback)
            local index = contains(self.callbacks, callback)

            if index ~= nil then
                table.remove(self.callbacks, index)
            end

            return self
        end

        function Item:fire_events()
            local list = self.callbacks

            for i = 1, #list do
                list[i](self)
            end
        end
    end

    function menu.new(fn, ...)
        local argv, argc = { }, select('#', ...)

        for i = 1, argc do
            argv[i] = select(i, ...)
        end

        if fn == ui.new_button and type(argv[4]) ~= 'function' then
            argv[4] = DUMMY
        end

        local ref = fn(unpack(argv, 1, argc))

        local item = Item:new(ref) do
            item:init(...)
        end

        return item
    end

    function menu.get_event_bus()
        return event_bus
    end
end

local menu_logic = { } do
    local item_data = { }
    local item_list = { }

    local logic_events = event_system:new()

    function menu_logic.get_event_bus()
        return logic_events
    end

    function menu_logic.set(item, value)
        if item == nil or item.ref == nil then
            return
        end

        item_data[item.ref] = value
    end

    function menu_logic.force_update()
        for i = 1, #item_list do
            local item = item_list[i]

            if item == nil then
                goto continue
            end

            local ref = item.ref

            if ref == nil then
                goto continue
            end

            local value = item_data[ref]

            if value == nil then
                goto continue
            end

            item:set_visible(value)
            item_data[ref] = false

            ::continue::
        end
    end

    local menu_events = menu.get_event_bus() do
        local function on_item_init(item)
            item_data[item.ref] = false
            item:set_visible(false)

            table.insert(item_list, item)
        end

        local function on_item_changed(...)
            logic_events.update:fire(...)
            menu_logic.force_update()
        end

        menu_events.item_init:set(on_item_init)
        menu_events.item_changed:set(on_item_changed)
    end
end

local text_anims = { } do
    local function u8(str)
        local chars = { }
        local count = 0

        for c in string.gmatch(str, '.[\128-\191]*') do
            count = count + 1
            chars[count] = c
        end

        return chars, count
    end

    function text_anims.gradient(str, time, r1, g1, b1, a1, r2, g2, b2, a2)
        local list = { }

        local strbuf, strlen = u8(str)
        local div = 1 / (strlen - 1)

        local delta_r = r2 - r1
        local delta_g = g2 - g1
        local delta_b = b2 - b1
        local delta_a = a2 - a1

        for i = 1, strlen do
            local char = strbuf[i]

            local t = time do
                t = t % 2

                if t > 1 then
                    t = 2 - t
                end
            end

            local r = r1 + t * delta_r
            local g = g1 + t * delta_g
            local b = b1 + t * delta_b
            local a = a1 + t * delta_a

            local hex = utils.to_hex(r, g, b, a)

            table.insert(list, '\a')
            table.insert(list, hex)
            table.insert(list, char)

            time = time + div
        end

        return table.concat(list)
    end
end

local text_fmt = { } do
    local function decompose(str)
        local result, len = { }, #str

        local i, j = str:find('\a', 1)

        if i == nil then
            table.insert(result, {
                str, nil
            })
        end

        if i ~= nil and i > 1 then
            table.insert(result, {
                str:sub(1, i - 1), nil
            })
        end

        while i ~= nil do
            local hex = nil

            if str:sub(j + 1, j + 7) == 'DEFAULT' then
                j = j + 8
            else
                hex = str:sub(j + 1, j + 8)
                j = j + 9
            end

            local m, n = str:find('\a', j)

            if m == nil then
                if j <= len then
                    table.insert(result, {
                        str:sub(j), hex
                    })
                end

                break
            end

            table.insert(result, {
                str:sub(j, m - 1), hex
            })

            i, j = m, n
        end

        return result
    end

    function text_fmt.color(str)
        local list = decompose(str)
        local len = #list

        return list, len
    end
end

local localplayer = { } do
    local pre_flags = 0
    local post_flags = 0

    localplayer.is_moving = false
    localplayer.is_onground = false
    localplayer.is_crouched = false

    localplayer.body_yaw = 0
    localplayer.sent_packets = 0

    localplayer.duck_amount = 0.0

    localplayer.velocity = vector()
    localplayer.velocity2d_sqr = 0

    localplayer.move_dir = vector()
    localplayer.eye_position = vector()

    -- from @enq
    local function is_peeking(player)
        local should, vulnerable = false, false
        local velocity = vector(entity.get_prop(player, 'm_vecVelocity'))

        local eye = vector(client.eye_position())
        local peye = utils.extrapolate(eye, velocity, 14)

        local enemies = entity.get_players(true)

        for i = 1, #enemies do
            local enemy = enemies[i]

            local esp_data = entity.get_esp_data(enemy)

            if esp_data == nil then
                goto continue
            end

            if bit.band(esp_data.flags, bit.lshift(1, 11)) ~= 0 then
                vulnerable = true
                goto continue
            end

            local head = vector(entity.hitbox_position(enemy, 0))
            local phead = utils.extrapolate(head, velocity, 4)

            local entindex, damage = client.trace_bullet(player, peye.x, peye.y, peye.z, phead.x, phead.y, phead.z)

            if damage ~= nil and damage > 0 then
                should = true
                break
            end

            ::continue::
        end

        return should, vulnerable
    end

    local function get_body_yaw(player)
        local entity_info = c_entity(player)

        if entity_info == nil then
            return
        end

        local anim_state = entity_info:get_anim_state()

        if anim_state == nil then
            return
        end

        local eye_angles_y = anim_state.eye_angles_y
        local goal_feet_yaw = anim_state.goal_feet_yaw

        return utils.normalize(
            eye_angles_y - goal_feet_yaw, -180, 180
        )
    end

    local function on_pre_predict_command(cmd)
        local me = entity.get_local_player()

        if me == nil then
            return
        end

        pre_flags = entity.get_prop(me, 'm_fFlags')
    end

    local function on_predict_command(cmd)
        local me = entity.get_local_player()

        if me == nil then
            return
        end

        post_flags = entity.get_prop(me, 'm_fFlags')
    end

    local function on_setup_command(cmd)
        local me = entity.get_local_player()

        if me == nil then
            return
        end

        local peeking, vulnerable = is_peeking(me)

        local is_onground = bit.band(pre_flags, 1) ~= 0
            and bit.band(post_flags, 1) ~= 0

        local velocity = vector(entity.get_prop(me, 'm_vecVelocity'))
        local duck_amount = entity.get_prop(me, 'm_flDuckAmount')

        local velocity2d_sqr = velocity:length2dsqr()

        localplayer.is_moving = velocity2d_sqr > 5 * 5
        localplayer.is_onground = is_onground

        localplayer.is_peeking = peeking
        localplayer.is_vulnerable = vulnerable

        if cmd.chokedcommands == 0 then
            localplayer.body_yaw = get_body_yaw(me)

            localplayer.sent_packets = (
                localplayer.sent_packets + 1
            )

            localplayer.eye_position = client.eye_position()
            localplayer.is_crouched = duck_amount > 0.5
            localplayer.duck_amount = duck_amount
        end

        localplayer.velocity = velocity
        localplayer.velocity2d_sqr = velocity2d_sqr

        localplayer.move_dir = vector(
            cmd.forwardmove, cmd.sidemove, 0
        )
    end

    client.set_event_callback('pre_predict_command', on_pre_predict_command)
    client.set_event_callback('predict_command', on_predict_command)
    client.set_event_callback('setup_command', on_setup_command)
end

local exploit = { } do
    local BREAK_LAG_COMPENSATION_DISTANCE_SQR = 64 * 64

    local max_tickbase = 0
    local run_command_number = 0

    local data = {
        old_origin = vector(),
        old_simtime = 0.0,

        shift = false,
        breaking_lc = false,

        active = false,
        charged = false,

        defensive = {
            force = false,
            left = 0,
            max = 0,
            active = false,
        },

        lagcompensation = {
            distance = 0.0,
            teleport = false
        }
    }

    local function update_tickbase(me)
        data.shift = globals.tickcount() > entity.get_prop(me, 'm_nTickBase')
    end

    local function update_teleport(old_origin, new_origin)
        local delta = new_origin - old_origin
        local distance = delta:lengthsqr()

        local is_teleport = distance > BREAK_LAG_COMPENSATION_DISTANCE_SQR

        data.breaking_lc = is_teleport

        data.lagcompensation.distance = distance
        data.lagcompensation.teleport = is_teleport
    end

    local function update_lagcompensation(me)
        local old_origin = data.old_origin
        local old_simtime = data.old_simtime

        local origin = vector(entity.get_origin(me))
        local simtime = toticks(entity.get_prop(me, 'm_flSimulationTime'))

        if old_simtime ~= nil then
            local delta = simtime - old_simtime

            if delta < 0 or delta > 0 and delta <= 64 then
                update_teleport(old_origin, origin)
            end
        end

        data.old_origin = origin
        data.old_simtime = simtime
    end

    local function update_defensive_tick(me)
        local tickbase = entity.get_prop(me, 'm_nTickBase')

        if math.abs(tickbase - max_tickbase) > 64 then
            -- nullify highest tickbase if the difference is too big
            max_tickbase = 0
        end

        local defensive_ticks_left = 0

        -- defensive effect can be achieved because the lag compensation is made so that
        -- it doesn't write records if the current simulation time is less than/equals highest acknowledged simulation time
        -- https://gitlab.com/KittenPopo/csgo-2018-source/-/blame/main/game/server/player_lagcompensation.cpp#L723

        if tickbase > max_tickbase then
            max_tickbase = tickbase
        elseif max_tickbase > tickbase then
            defensive_ticks_left = math.min(14, math.max(0, max_tickbase - tickbase - 1))
        end

        if defensive_ticks_left > 0 then
            data.breaking_lc = true
            data.defensive.left = defensive_ticks_left
            data.defensive.active = true

            if data.defensive.max == 0 then
                data.defensive.max = defensive_ticks_left
            end
        else
            data.defensive.left = 0
            data.defensive.max = 0
            data.defensive.active = false
        end
    end

    local function update_charged(me)
        local m_nTickBase = entity.get_prop(me, 'm_nTickBase')
        local shift = math.floor(m_nTickBase - globals.tickcount() - 3 - toticks(client.latency()) * 0.4)

        local fakelag_limit = ui.get(reference.antiaim.fake_lag.limit)
        local wanted = -15 + (fakelag_limit - 1) + 5 -- error margin

        data.charged = shift <= wanted
    end

    local function update_active()
        local doubletap_active = reference.is_double_tap_active()
        local hideshots_active = reference.is_on_shot_antiaim_active()

        data.active = doubletap_active or hideshots_active
    end

    function exploit.get()
        return data
    end

    local function on_predict_command(cmd)
        local me = entity.get_local_player()

        if me == nil then
            return
        end

        if cmd.command_number == run_command_number then
            update_defensive_tick(me)
            run_command_number = nil
        end
    end

    local function on_setup_command(cmd)
        local me = entity.get_local_player()

        if me == nil then
            return
        end

        update_charged(me)
        update_active()
    end

    local function on_run_command(e)
        local me = entity.get_local_player()

        if me == nil then
            return
        end

        update_tickbase(me)

        run_command_number = e.command_number
    end

    local function on_net_update_start()
        local me = entity.get_local_player()

        if me == nil then
            return
        end

        update_lagcompensation(me)
    end

    client.set_event_callback('predict_command', on_predict_command)
    client.set_event_callback('setup_command', on_setup_command)
    client.set_event_callback('run_command', on_run_command)

    client.set_event_callback('net_update_start', on_net_update_start)
end

local conditions = { } do
    local list = { }
    local count = 0

    local function add(state)
        count = count + 1
        list[count] = state
    end

    local function clear_list()
        for i = 1, count do
            list[i] = nil
        end

        count = 0
    end

    local function update_onground()
        if not localplayer.is_onground then
            return
        end

        if localplayer.is_moving then
            add 'Moving'

            if localplayer.is_crouched then
                return
            end

            if reference.is_slow_motion() then
                add 'Slow Walk'
            end

            return
        end

        add 'Standing'
    end

    local function update_crouched()
        if not localplayer.is_crouched then
            return
        end

        add 'Crouching'

        if localplayer.is_moving then
            add 'Crouching & Move'
        end
    end

    local function update_in_air()
        if localplayer.is_onground then
            return
        end

        add 'Air'

        if localplayer.is_crouched then
            add 'Air & Crouched'
        end
    end

    function conditions.get()
        return list
    end

    local function on_setup_command()
        clear_list()

        update_onground()
        update_crouched()
        update_in_air()
    end

    client.set_event_callback(
        'setup_command',
        on_setup_command
    )
end

local menu_elements = { } do
    local conditions = {
        'Shared',
        'Standing',
        'Moving',
        'Slow Walk',
        'Crouching',
        'Crouching & Move',
        'Air',
        'Air & Crouched',
        'Freestanding',
        'Manual AA',
        'Legit AA',
    }

    local function new_key(str, key)
        if str:find '\n' == nil then
            str = str .. '\n'
        end

        return str .. key
    end

    local function lock_unselection(item, default_value)
        local old_value = item:get()

        if #old_value == 0 then
            if default_value == nil then
                if item.type == 'multiselect' then
                    default_value = item.list
                elseif item.type == 'list' then
                    default_value = { }

                    for i = 1, #item.list do
                        default_value[i] = i
                    end
                end
            end

            old_value = default_value
            item:set(default_value)
        end

        item:set_callback(function()
            local value = item:get()

            if #value > 0 then
                old_value = value
            else
                item:set(old_value)
            end
        end)
    end

    local function lock_clr()
        return utils.to_hex(75, 75, 75, 255)
    end

    local function def_clr()
        return utils.to_hex(200, 200, 200, 255)
    end

    local category_selector = { } do
        menu_elements.category_selector = category_selector

        category_selector.categories_label = menu.new(
            ui.new_label, 'AA', 'Fake lag', new_key('\n Categories Label', 'category_selector')
        )

        category_selector.categories = menu.new(
            ui.new_combobox, 'AA', 'Fake lag', new_key('\n Categories', 'category_selector'), {'Home', 'Anti-Aim'}
        )

        local callbacks do
            local ref_menu_color = ui.reference(
                'Misc', 'Settings', 'Menu color'
            )

            local function get_label_categories()
                local name

                local color_a = color(reference.get_color())

                if category_selector.categories:get() == 'Home' then
                    name = string.format(
                        '\a%s%s\a%s â€¢ \a%s%s\a%s â€¢ \a%s%s \a%s| %s',
                        reference.get_color(true),
                        'î…­',
                        lock_clr(),
                        def_clr(),
                        'î„•',
                        lock_clr(),
                        def_clr(),
                        'î‡ ',
                        lock_clr(),
                        text_anims.gradient('chernobyl', 0.15, 75, 75, 75, 255, color_a.r, color_a.g, color_a.b, color_a.a)
                    )
                end


                if category_selector.categories:get() == 'Anti-Aim' then
                    name = string.format(
                        '\a%s%s\a%s â€¢ \a%s%s\a%s â€¢ \a%s%s \a%s| %s',
                        def_clr(),
                        'î…­',
                        lock_clr(),
                        def_clr(),
                        'î„•',
                        lock_clr(),
                        reference.get_color(true),
                        'î‡ ',
                        lock_clr(),
                        text_anims.gradient('chernobyl', 0.15, 75, 75, 75, 255, color_a.r, color_a.g, color_a.b, color_a.a)
                    )
                end

                category_selector.categories_label:set(name)
            end

            local function on_menu_color(item)
                get_label_categories()
            end

            category_selector.categories:set_callback(
                get_label_categories
            )

            ui_callback.set(
                ref_menu_color,
                on_menu_color
            )

            get_label_categories()
        end
    end

    local home = { } do
        menu_elements.home = home

        local selector = { } do
            home.selector = selector

            selector.separator = menu.new(
                ui.new_label, 'AA', 'Fake lag', new_key('\n Separator', 'home selector')
            )

            selector.tab_label = menu.new(
                ui.new_label, 'AA', 'Fake lag', new_key('\n Tab Label', 'home selector')
            )

            selector.tab = menu.new(
                ui.new_combobox, 'AA', 'Fake lag', new_key('\n Tab', 'home selector'), {'Local'}
            )

            selector.separator2 = menu.new(
                ui.new_label, 'AA', 'Fake lag', new_key('\n Separator2', 'home selector')
            )

            local callbacks do
                local ref_menu_color = ui.reference(
                    'Misc', 'Settings', 'Menu color'
                )

                local function get_label_tab()
                    local name

                    if selector.tab:get() == 'Local' then
                        name = string.format(
                            'Type \a%s ~  \a%s%s',
                            lock_clr(),
                            reference.get_color(true),
                            'î†ˆ'
                        )
                    end

                    selector.tab_label:set(name)
                end

                local function on_menu_color(item)
                    get_label_tab()
                end

                selector.tab:set_callback(
                    get_label_tab
                )


                ui_callback.set(
                    ref_menu_color,
                    on_menu_color
                )

                get_label_tab()
            end
        end

        local bred_ebaniy = { } do
            home.bred_ebaniy = bred_ebaniy

                local wrapper_slider_label = theme_controller.wrap(new_key(string.format('Info  \a%s~  ${%s}', lock_clr(), 'î„¥'), 'config_local'))

            bred_ebaniy.slider_label = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_slider_label()
            )

            theme_controller.push(bred_ebaniy.slider_label, wrapper_slider_label)

            bred_ebaniy.slider = menu.new(
                ui.new_slider, 'AA', 'Anti-aimbot angles', '\n Slider ebat', 0, 2, 1, true, '', 0, {
                    [0] = string.format('\a%sî…» \a%schernobyl', lock_clr(), def_clr()),
                    [1] = string.format('\a%sî‡‹ \a%sprivate', lock_clr(), def_clr()),
                    [2] = string.format('\a%sî‡‹ \a%sbuild', lock_clr(), def_clr())
                }
            )

            bred_ebaniy.discord_server = menu.new(
                ui.new_button, 'AA', 'Anti-aimbot angles', string.format('chernobyl  \a%s~  \a%s%s', lock_clr(), def_clr(), 'î„¶'), DUMMY
            )

            bred_ebaniy.youtube_1 = menu.new(
                ui.new_button, 'AA', 'Anti-aimbot angles', string.format('private  \a%s~  \a%s%s', lock_clr(), def_clr(), 'î†‡'), DUMMY
            )

            bred_ebaniy.youtube_2 = menu.new(
                ui.new_button, 'AA', 'Anti-aimbot angles', string.format('build  \a%s~  \a%s%s', lock_clr(), def_clr(), 'î†‡'), DUMMY
            )

            bred_ebaniy.separator = menu.new(
                ui.new_label, 'AA', 'Anti-aimbot angles', new_key('\n Separator bred_ebaniy', 'config_local')
            )
        end

        local config_local = { } do
            home.config_local = config_local

            local function name_author_label()
                return string.format(
                        '\a%s%s \a%s~  \a%sAuthor \a%s| \a%s%s',
                        reference.get_color(true),
                        'î„½',
                        lock_clr(),
                        def_clr(),
                        lock_clr(),
                        reference.get_color(true),
                        '1'
                    )
            end

            local function name_data_label()
                return string.format(
                        '\a%s%s \a%s~  \a%sCreated at \a%s| \a%s%s',
                        reference.get_color(true),
                        'î„¡',
                        lock_clr(),
                        def_clr(),
                        lock_clr(),
                        reference.get_color(true),
                        'private'
                    )
            end

            local welcome = { } do
                config_local.welcome = welcome

                local wrapper_user_label = theme_controller.wrap(new_key(string.format(
                        '\a%s%s \a%s~  \a%sWelcome \a%s| \a%s%s',
                        reference.get_color(true),
                        'î„™',
                        lock_clr(),
                        def_clr(),
                        lock_clr(),
                        reference.get_color(true),
                        script.user
                ), 'config_local'))

                welcome.user = menu.new(
                        ui.new_label, 'AA', 'Fake lag', wrapper_user_label()
                )

                theme_controller.push(welcome.user, wrapper_user_label)

                local wrapper_build_label = theme_controller.wrap(new_key(string.format(
                        '\a%s%s \a%s~  \a%sYour build \a%s| \a%s%s',
                        reference.get_color(true),
                        'î†’',
                        lock_clr(),
                        def_clr(),
                        lock_clr(),
                        reference.get_color(true),
                        script.build
                ), 'config_local'))

                welcome.build = menu.new(
                        ui.new_label, 'AA', 'Fake lag', wrapper_build_label()
                )

                theme_controller.push(welcome.build, wrapper_build_label)

                end


            config_local.list = menu.new(
                ui.new_listbox, 'AA', 'Anti-aimbot angles', new_key('\n List', 'config_local'), {'', ''}
            )

            config_local.separator = menu.new(
                ui.new_label, 'AA', 'Anti-aimbot angles', new_key('\n Separator', 'config_local')
            )

            config_local.author = menu.new(
                ui.new_label, 'AA', 'Anti-aimbot angles', name_author_label()
            )

            config_local.data = menu.new(
                ui.new_label, 'AA', 'Anti-aimbot angles', name_data_label()
            )

            config_local.input = menu.new(
                ui.new_textbox, 'AA', 'Other', new_key('\n Input', 'config_local')
            )

            config_local.load = menu.new(
                ui.new_button, 'AA', 'Other', string.format('Load  \a%s~  \a%s%s', lock_clr(), def_clr(), 'î†—'), DUMMY
            )

            config_local.save = menu.new(
                ui.new_button, 'AA', 'Other', string.format('Save  \a%s~  \a%s%s', lock_clr(), def_clr(), 'î„…'), DUMMY
            )

            config_local.import = menu.new(
                ui.new_button, 'AA', 'Other', string.format('Import  \a%s~  \a%s%s', lock_clr(), def_clr(), 'î…¥'), DUMMY
            )

            config_local.export = menu.new(
                ui.new_button, 'AA', 'Other', string.format('Export  \a%s~  \a%s%s', lock_clr(), def_clr(), 'î‡²'), DUMMY
            )

            config_local.delete = menu.new(
                ui.new_button, 'AA', 'Other', string.format('Delete  \a%s~  \a%s%s', lock_clr(), 'FF173CFF', 'î„‡'), DUMMY
            )

            local callbacks do
                local ref_menu_color = ui.reference(
                    'Misc', 'Settings', 'Menu color'
                )

                local function on_menu_color(item)
                    config_local.author:set(name_author_label())
                    config_local.data:set(name_data_label())
                end

                ui_callback.set(
                    ref_menu_color,
                    on_menu_color
                )
            end
        end

        local configs_cloud = { } do
            home.configs_cloud = configs_cloud

            --Ñ‚Ñ‹ Ð´ÑƒÐ¼Ð°Ð» Ñ‚ÑƒÑ‚ Ñ‡Ñ‚Ð¾-Ñ‚Ð¾ Ð±ÑƒÐ´ÐµÑ‚ ? ??????
        end
    end

    local antiaim = { } do
        menu_elements.antiaim = antiaim

        local selector = { } do
            antiaim.selector = selector

            selector.separator = menu.new(
                ui.new_label, 'AA', 'Fake lag', new_key('\n Separator', 'antiaim selector')
            )

            selector.tab_label = menu.new(
                ui.new_label, 'AA', 'Fake lag', new_key('\n Tab Label', 'antiaim selector')
            )

            selector.tab = menu.new(
                ui.new_combobox, 'AA', 'Fake lag', new_key('\n Tab', 'antiaim selector'), {'Builder', 'Features'}
            )

            selector.separator2 = menu.new(
                ui.new_label, 'AA', 'Fake lag', new_key('\n Separator2', 'antiaim selector')
            )

            local callbacks do
                local ref_menu_color = ui.reference(
                    'Misc', 'Settings', 'Menu color'
                )

                local function get_label_tab()
                    local name

                    if selector.tab:get() == 'Builder' then
                        name = string.format(
                            'Type \a%s ~  \a%s%s',
                            lock_clr(),
                            reference.get_color(true),
                            'î„¥'
                        )
                    end

                    if selector.tab:get() == 'Features' then
                        name = string.format(
                            'Type \a%s ~  \a%s%s',
                            lock_clr(),
                            reference.get_color(true),
                            'î…ž'
                        )
                    end

                    selector.tab_label:set(name)
                end

                local function on_menu_color(item)
                    get_label_tab()
                end

                selector.tab:set_callback(
                    get_label_tab
                )

                ui_callback.set(
                    ref_menu_color,
                    on_menu_color
                )

                get_label_tab()
            end
        end

        local builder = { } do
            antiaim.builder = builder

            local current_state = conditions[1]

            local function create_defensive_items(state)
                local items = { }

                local function hash(key)
                    return state .. ':' .. ':defensive_' .. key
                end

                items.force_defensive = config_system.push(
                    'Builder', hash 'force_defensive', menu.new(
                        ui.new_checkbox, 'AA', 'Other', new_key('Force defensive', hash 'force_defensive')
                    )
                )

                items.enabled = config_system.push(
                    'Builder', hash 'enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Other', new_key('Defensive anti-aim', hash 'enabled')
                    )
                )

                items.type = config_system.push(
                    'Builder', hash 'type', menu.new(
                        ui.new_combobox, 'AA', 'Other', new_key('\n Type', hash 'type'), {
                            'Default',
                            'Flick'
                        }
                    )
                )

                local wrapper_pitch_label = theme_controller.wrap(new_key('Pitch  ${Â»}', hash 'pitch'))

                items.pitch_label = menu.new(
                    ui.new_label, 'AA', 'Other', wrapper_pitch_label()
                )

                theme_controller.push(items.pitch_label, wrapper_pitch_label)

                items.pitch = config_system.push(
                    'Builder', hash 'pitch', menu.new(
                        ui.new_combobox, 'AA', 'Other', new_key('\n Pitch', hash 'pitch'), {
                            'Off',
                            'Static',
                            'Switch',
                            'Spin',
                            'Random'
                        }
                    )
                )

                local wrapper_pitch_offset_label = theme_controller.wrap(new_key('Offset ${â€¢}', hash 'pitch_offset'))

                items.pitch_offset_label = menu.new(
                    ui.new_label, 'AA', 'Other', wrapper_pitch_offset_label()
                )

                theme_controller.push(items.pitch_offset_label, wrapper_pitch_offset_label)


                items.pitch_offset = config_system.push(
                    'Builder', hash 'pitch_offset ', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('\n', hash 'pitch_offset '), -89, 89, 0, true, 'Â°'
                    )
                )

                local wrapper_pitch_label_1 = theme_controller.wrap(new_key('From ${â€¢}', hash 'pitch'))

                items.pitch_label_1 = menu.new(
                    ui.new_label, 'AA', 'Other', wrapper_pitch_label_1()
                )

                theme_controller.push(items.pitch_label_1, wrapper_pitch_label_1)


                items.pitch_offset_1 = config_system.push(
                    'Builder', hash 'pitch_offset_1', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('\n', hash 'pitch_offset_1'), -89, 89, 0, true, 'Â°'
                    )
                )

                local wrapper_pitch_label_2 = theme_controller.wrap(new_key('To ${â€¢}', hash 'pitch'))

                items.pitch_label_2 = menu.new(
                    ui.new_label, 'AA', 'Other', wrapper_pitch_label_2()
                )

                theme_controller.push(items.pitch_label_2, wrapper_pitch_label_2)

                items.pitch_offset_2 = config_system.push(
                    'Builder', hash 'pitch_offset_2', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('\n', hash 'pitch_offset_2'), -89, 89, 0, true, 'Â°'
                    )
                )

                local wrapper_pitch_offset_delay_label = theme_controller.wrap(new_key('Delay ${â€¢}', hash 'pitch_offset_delay'))

                items.pitch_offset_delay_label = menu.new(
                    ui.new_label, 'AA', 'Other', wrapper_pitch_offset_delay_label()
                )

                theme_controller.push(items.pitch_offset_delay_label, wrapper_pitch_offset_delay_label)

                items.pitch_offset_delay = config_system.push(
                    'Builder', hash 'pitch_offset_delay', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('\n Delay', hash 'pitch_offset_delay'), 1, 10, 1, true, 't', 1, {
                            [1] = 'Off'
                        }
                    )
                )

                local wrapper_pitch_offset_speed_label = theme_controller.wrap(new_key('Speed ${â€¢}', hash 'pitch_offset_speed'))

                items.pitch_offset_speed_label = menu.new(
                    ui.new_label, 'AA', 'Other', wrapper_pitch_offset_speed_label()
                )

                theme_controller.push(items.pitch_offset_speed_label, wrapper_pitch_offset_speed_label)

                items.pitch_offset_speed = config_system.push(
                    'Builder', hash 'pitch_offset_speed', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('\n Speed', hash 'pitch_offset_speed'), 0, 20, 0, true, nil, 1
                    )
                )

                items.yaw = config_system.push(
                    'Builder', hash 'yaw', menu.new(
                        ui.new_combobox, 'AA', 'Other', new_key('Yaw', hash 'yaw'), {
                            'Off',
                            'Static',
                            'Switch',
                            'Spin',
                            'Random'
                        }
                    )
                )

                local wrapper_yaw_offset_label = theme_controller.wrap(new_key('Offset ${â€¢}', hash 'yaw_offset'))

                items.yaw_offset_label = menu.new(
                    ui.new_label, 'AA', 'Other', wrapper_yaw_offset_label()
                )

                theme_controller.push(items.yaw_offset_label, wrapper_yaw_offset_label)

                local wrapper_yaw_label_1 = theme_controller.wrap(new_key('From ${â€¢}', hash 'yaw'))

                items.yaw_label_1 = menu.new(
                    ui.new_label, 'AA', 'Other', wrapper_yaw_label_1()
                )

                theme_controller.push(items.yaw_label_1, wrapper_yaw_label_1)

                items.yaw_offset_1 = config_system.push(
                    'Builder', hash 'yaw_offset_1', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('\n', hash 'yaw_offset_1'), -180, 180, 0, true, 'Â°'
                    )
                )

                local wrapper_yaw_label_2 = theme_controller.wrap(new_key('To ${â€¢}', hash 'yaw'))

                items.yaw_label_2 = menu.new(
                    ui.new_label, 'AA', 'Other', wrapper_yaw_label_2()
                )

                theme_controller.push(items.yaw_label_2, wrapper_yaw_label_2)


                items.yaw_offset_2 = config_system.push(
                    'Builder', hash 'yaw_offset_2', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('\n', hash 'yaw_offset_2'), -180, 180, 0, true, 'Â°'
                    )
                )

                local wrapper_yaw_offset_delay_label = theme_controller.wrap(new_key('Delay ${â€¢}', hash 'yaw_offset_delay'))

                items.yaw_offset_delay_label = menu.new(
                    ui.new_label, 'AA', 'Other', wrapper_yaw_offset_delay_label()
                )

                theme_controller.push(items.yaw_offset_delay_label, wrapper_yaw_offset_delay_label)


                items.yaw_offset_delay = config_system.push(
                    'Builder', hash 'yaw_offset_delay', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('\n Delay', hash 'yaw_offset_delay'), 1, 10, 1, true, 't', 1, {
                            [1] = 'Off'
                        }
                    )
                )

                items.yaw_offset = config_system.push(
                    'Builder', hash 'yaw_offset', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('\n', hash 'yaw_offset'), -180, 180, 0, true, 'Â°', 1
                    )
                )

                local wrapper_yaw_offset_flick_label = theme_controller.wrap(new_key('Yaw offset ${â€¢}', hash 'flick_yaw_offset'))

                items.yaw_offset_flick_label = menu.new(
                    ui.new_label, 'AA', 'Other', wrapper_yaw_offset_flick_label()
                )

                theme_controller.push(items.yaw_offset_flick_label, wrapper_yaw_offset_flick_label)

                items.yaw_offset_flick = config_system.push(
                    'Builder', hash 'flick_yaw_offset', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('\n Yaw offset', hash 'flick_yaw_offset'), 0, 180, 90, true, 'Â°', 1
                    )
                )

                return items
            end

            local function create_builder_items(state, std_key)
                local items = { }

                local is_shared = state == 'Shared'
                local is_legit_aa = state == 'Legit AA'

                local is_freestanding = state == 'Freestanding'
                local is_manual_aa = state == 'Manual AA'

                local function hash(key)
                    return state .. ':' .. key
                end

                if std_key ~= nil then
                    function hash(key)
                        return state .. ':' .. key .. ':' .. std_key
                    end
                end

                if is_shared then
                    local wrapper_yaw_base_label = theme_controller.wrap(new_key('Yaw base ${Â»}', hash 'yaw_base'))

                    items.yaw_base_label = menu.new(
                        ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_yaw_base_label()
                    )

                    theme_controller.push(items.yaw_base_label, wrapper_yaw_base_label)
                end

                if not is_shared then
                    local enabled_name = string.format(
                        'Override %s', state
                    )

                    items.enabled = config_system.push(
                        'Builder', hash 'enabled', menu.new(
                            ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key(
                                enabled_name, hash 'enabled'
                            )
                        )
                    )
                end

                if is_legit_aa then
                    items.bomb_e_fix = config_system.push(
                        'Builder', hash 'bomb_e_fix', menu.new(
                            ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key(
                                'Bomb E fix', hash 'bomb_e_fix'
                            )
                        )
                    )
                end

                if not is_freestanding then
                    items.yaw_base = config_system.push(
                        'Builder', hash 'yaw_base', menu.new(
                            ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('\n Yaw Base', hash 'yaw_base'), {
                                'At targets',
                                'Local view'
                            }
                        )
                    )

                    local wrapper_yaw_type_label = theme_controller.wrap(new_key('Yaw ${Â»}', hash 'yaw_type'))

                    items.yaw_type_label = menu.new(
                        ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_yaw_type_label()
                    )

                    theme_controller.push(items.yaw_type_label, wrapper_yaw_type_label)

                    items.yaw_type = config_system.push(
                        'Builder', hash 'yaw_type', menu.new(
                            ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('\n Yaw', hash 'yaw_type'), {
                                '180',
                                'Left / Right'
                            }
                        )
                    )

                    local yaw_180 do
                        local wrapper_yaw_180_offset_label = theme_controller.wrap(new_key('Offset ${â€¢}', hash 'yaw_180_offset'))

                        items.yaw_180_offset_label = menu.new(
                            ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_yaw_180_offset_label()
                        )

                        theme_controller.push(items.yaw_180_offset_label, wrapper_yaw_180_offset_label)

                        items.yaw_180_offset = config_system.push(
                            'Builder', hash 'yaw_180_offset', menu.new(
                                ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n Offset', hash 'yaw_180_offset'), -180, 180, 0, true, 'Â°'
                            )
                        )

                        local wrapper_yaw_random_label = theme_controller.wrap(new_key('Randomization ${â€¢}', hash 'yaw_random'))

                        items.yaw_random_label = menu.new(
                            ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_yaw_random_label()
                        )

                        theme_controller.push(items.yaw_random_label, wrapper_yaw_random_label)

                        items.yaw_random = config_system.push(
                            'Builder', hash 'yaw_random', menu.new(
                                ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n Randomization', hash 'yaw_random'), 0, 30, 0, true, '%'
                            )
                        )
                    end

                    local yaw_lr do
                        local yaw_side do
                            local wrapper_yaw_side_label = theme_controller.wrap(new_key('Side ${Â»}', hash 'yaw_side'))

                            items.yaw_side_label = menu.new(
                                ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_yaw_side_label()
                            )

                            theme_controller.push(items.yaw_side_label, wrapper_yaw_side_label)

                            items.yaw_side = config_system.push(
                                'Builder', hash 'yaw_side', menu.new(
                                    ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('\n Side', hash 'yaw_side'), {
                                        'Left',
                                        'Right',
                                    }
                                )
                            )
                        end

                        local left_yaw do
                            local wrapper_yaw_left_offset_label = theme_controller.wrap(new_key('Offset ${â€¢}', hash 'yaw_left_offset'))

                            items.yaw_left_offset_label = menu.new(
                                ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_yaw_left_offset_label()
                            )

                            theme_controller.push(items.yaw_left_offset_label, wrapper_yaw_left_offset_label)

                            items.yaw_left_offset = config_system.push(
                                'Builder', hash 'yaw_left_offset', menu.new(
                                    ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n Offset', hash 'yaw_left_offset'), -180, 180, 0, true, 'Â°'
                                )
                            )

                            local wrapper_yaw_left_random_label = theme_controller.wrap(new_key('Randomization ${â€¢}', hash 'yaw_left_random'))

                            items.yaw_left_random_label = menu.new(
                                ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_yaw_left_random_label()
                            )

                            theme_controller.push(items.yaw_left_random_label, wrapper_yaw_left_random_label)

                            items.yaw_left_random = config_system.push(
                                'Builder', hash 'yaw_left_random', menu.new(
                                    ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n Randomization', hash 'yaw_left_random'), 0, 30, 0, true, '%'
                                )
                            )

                            items.yaw_left_delay = { }

                            for i = 1, 3 do
                                local hash_label = hash(string.format('yaw_left_label_%s', i))
                                local hash_delay = hash(string.format('yaw_left_delay_%s', i))

                                local wrapper_label = theme_controller.wrap(new_key('Delay ${â€¢}', hash_label))

                                local min_delay = 1
                                local max_delay = 10

                                if i ~= 1 then
                                    min_delay = 0
                                end

                                local item_label = menu.new(
                                    ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_label()
                                )

                                local item_delay = config_system.push(
                                    'Builder', hash_delay, menu.new(
                                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n Delay', hash_delay), min_delay, max_delay, min_delay, true, 't', 1, {
                                            [min_delay] = 'Off'
                                        }
                                    )
                                )

                                theme_controller.push(item_label, wrapper_label)

                                items.yaw_left_delay[i] = {
                                    label = item_label,
                                    delay = item_delay
                                }
                            end
                        end

                        local right_yaw do
                            local wrapper_yaw_right_offset_label = theme_controller.wrap(new_key('Offset ${â€¢}', hash 'yaw_right_offset'))

                            items.yaw_right_offset_label = menu.new(
                                ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_yaw_right_offset_label()
                            )

                            theme_controller.push(items.yaw_right_offset_label, wrapper_yaw_right_offset_label)

                            items.yaw_right_offset = config_system.push(
                                'Builder', hash 'yaw_right_offset', menu.new(
                                    ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n Offset', hash 'yaw_right_offset'), -180, 180, 0, true, 'Â°'
                                )
                            )

                            local wrapper_yaw_right_random_label = theme_controller.wrap(new_key('Randomization ${â€¢}', hash 'yaw_right_random'))

                            items.yaw_right_random_label = menu.new(
                                ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_yaw_right_random_label()
                            )

                            theme_controller.push(items.yaw_right_random_label, wrapper_yaw_right_random_label)

                            items.yaw_right_random = config_system.push(
                                'Builder', hash 'yaw_right_random', menu.new(
                                    ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n Randomization', hash 'yaw_right_random'), 0, 30, 0, true, '%'
                                )
                            )

                            items.yaw_right_delay = { }

                            for i = 1, 3 do
                                local hash_label = hash(string.format('yaw_right_label_%s', i))
                                local hash_delay = hash(string.format('yaw_right_delay_%s', i))

                                local wrapper_label = theme_controller.wrap(new_key('Delay ${â€¢}', hash_label))

                                local min_delay = 1
                                local max_delay = 10

                                if i ~= 1 then
                                    min_delay = 0
                                end

                                local item_label = menu.new(
                                    ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_label()
                                )

                                local item_delay = config_system.push(
                                    'Builder', hash_delay, menu.new(
                                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n Delay', hash_delay), min_delay, max_delay, min_delay, true, 't', 1, {
                                            [min_delay] = 'Off'
                                        }
                                    )
                                )

                                theme_controller.push(item_label, wrapper_label)

                                items.yaw_right_delay[i] = {
                                    label = item_label,
                                    delay = item_delay
                                }
                            end
                        end
                    end

                    items.separator = menu.new(
                        ui.new_label, 'AA', 'Anti-aimbot angles', new_key('\n Separator', hash 'yaw')
                    )

                    local yaw_jitter do
                        local jitter_option do
                            local wrapper_yaw_jitter_label = theme_controller.wrap(new_key('Yaw jitter ${Â»}', hash 'yaw_jitter'))

                            items.yaw_jitter_label = menu.new(
                                ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_yaw_jitter_label()
                            )

                            theme_controller.push(items.yaw_jitter_label, wrapper_yaw_jitter_label)

                            items.yaw_jitter = config_system.push(
                                'Builder', hash 'yaw_jitter', menu.new(
                                    ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('\n Yaw jitter', hash 'yaw_jitter'), {
                                        'Off',
                                        'Offset',
                                        'Center',
                                        'Random',
                                        'Skitter',
                                        'X-way'
                                    }
                                )
                            )
                        end

                        local jitter_x_yaw do
                            local wrapper_jitter_x_way_label = theme_controller.wrap(new_key('Mode ${Â»}', hash 'jitter_x_way'))

                            items.jitter_x_way_label = menu.new(
                                ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_jitter_x_way_label()
                            )

                            theme_controller.push(items.jitter_x_way_label, wrapper_jitter_x_way_label)

                            items.jitter_x_way = config_system.push(
                                'Builder', hash 'jitter_x_way', menu.new(
                                    ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('\n Mode', hash 'jitter_x_way'), {
                                        'Auto',
                                        'Custom',
                                    }
                                )
                            )

                            local wrapper_x_way_ways_label = theme_controller.wrap(new_key('Ways ${â€¢}', hash 'x_way_offset'))

                            items.x_way_ways_label = menu.new(
                                ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_x_way_ways_label()
                            )

                            theme_controller.push(items.x_way_ways_label, wrapper_x_way_ways_label)

                            items.x_way_ways = config_system.push(
                                'Builder', hash 'x_way_ways', menu.new(
                                    ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n Ways', hash 'x_way_offset'), 3, 5, 3, true, 'w'
                                )
                            )

                            local wrapper_x_way_offset_1_label = theme_controller.wrap(new_key('First Offset ${â€¢}', hash 'x_way_offset'))

                            items.x_way_offset_1_label = menu.new(
                                ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_x_way_offset_1_label()
                            )

                            theme_controller.push(items.x_way_offset_1_label, wrapper_x_way_offset_1_label)

                            items.x_way_offset_1 = config_system.push(
                                'Builder', hash 'x_way_offset_1', menu.new(
                                    ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n Second Offset', hash 'x_way_offset'), -180, 180, 0, true, 'Â°'
                                )
                            )

                            local wrapper_x_way_offset_2_label = theme_controller.wrap(new_key('Second Offset ${â€¢}', hash 'x_way_offset'))

                            items.x_way_offset_2_label = menu.new(
                                ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_x_way_offset_2_label()
                            )

                            theme_controller.push(items.x_way_offset_2_label, wrapper_x_way_offset_2_label)

                            items.x_way_offset_2 = config_system.push(
                                'Builder', hash 'x_way_offset_2', menu.new(
                                    ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n First Offset', hash 'x_way_offset'), -180, 180, 0, true, 'Â°'
                                )
                            )

                            local wrapper_x_way_offset_3_label = theme_controller.wrap(new_key('Third Offset ${â€¢}', hash 'x_way_offset'))

                            items.x_way_offset_3_label = menu.new(
                                ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_x_way_offset_3_label()
                            )

                            theme_controller.push(items.x_way_offset_3_label, wrapper_x_way_offset_3_label)

                            items.x_way_offset_3 = config_system.push(
                                'Builder', hash 'x_way_offset_3', menu.new(
                                    ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n First Offset', hash 'x_way_offset'), -180, 180, 0, true, 'Â°'
                                )
                            )

                            local wrapper_x_way_offset_4_label = theme_controller.wrap(new_key('Fourth offset ${â€¢}', hash 'x_way_offset'))

                            items.x_way_offset_4_label = menu.new(
                                ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_x_way_offset_4_label()
                            )

                            theme_controller.push(items.x_way_offset_4_label, wrapper_x_way_offset_4_label)

                            items.x_way_offset_4 = config_system.push(
                                'Builder', hash 'x_way_offset_4', menu.new(
                                    ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n Fourth offset', hash 'x_way_offset'), -180, 180, 0, true, 'Â°'
                                )
                            )

                            local wrapper_x_way_offset_5_label = theme_controller.wrap(new_key('Fifth offset ${â€¢}', hash 'x_way_offset'))

                            items.x_way_offset_5_label = menu.new(
                                ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_x_way_offset_5_label()
                            )

                            theme_controller.push(items.x_way_offset_5_label, wrapper_x_way_offset_5_label)

                            items.x_way_offset_5 = config_system.push(
                                'Builder', hash 'x_way_offset_5', menu.new(
                                    ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n Fifth offset', hash 'x_way_offset'), -180, 180, 0, true, 'Â°'
                                )
                            )
                        end

                        local jitter_offset do
                            local wrapper_jitter_offset_label = theme_controller.wrap(new_key('Offset ${â€¢}', hash 'jitter_offset'))

                            items.jitter_offset_label = menu.new(
                                ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_jitter_offset_label()
                            )

                            theme_controller.push(items.jitter_offset_label, wrapper_jitter_offset_label)

                            items.jitter_offset = config_system.push(
                                'Builder', hash 'jitter_offset', menu.new(
                                    ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n Offset', hash 'jitter_offset'), -180, 180, 0, true, 'Â°'
                                )
                            )

                        end

                        local jitter_random do
                            local wrapper_jitter_random_label = theme_controller.wrap(new_key('Randomization ${â€¢}', hash 'jitter_random'))

                            items.jitter_random_label = menu.new(
                                ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_jitter_random_label()
                            )

                            theme_controller.push(items.jitter_random_label, wrapper_jitter_random_label)

                            items.jitter_random = config_system.push(
                                'Builder', hash 'jitter_random', menu.new(
                                    ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n Randomization', hash 'jitter_random'), 0, 30, 0, true, '%'
                                )
                            )
                        end
                    end

                    items.separator2 = menu.new(
                        ui.new_label, 'AA', 'Anti-aimbot angles', new_key('\n Separator2', hash 'jitter')
                    )
                end

                local wrapper_body_yaw_label = theme_controller.wrap(new_key('Body yaw  ${Â»}', hash 'body_yaw'))

                items.body_yaw_label = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_body_yaw_label()
                )

                theme_controller.push(items.body_yaw_label, wrapper_body_yaw_label)

                items.body_yaw = config_system.push(
                    'Builder', hash 'body_yaw', menu.new(
                        ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('\n Body yaw', hash 'body_yaw'), {
                            'Off',
                            'Opposite',
                            'Static',
                            'Jitter',
                            'Jitter Random'
                        }
                    )
                )

                local wrapper_body_yaw_offset_label = theme_controller.wrap(new_key('Offset ${â€¢}', hash 'body_yaw_offset'))

                items.body_yaw_offset_label = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_body_yaw_offset_label()
                )

                theme_controller.push(items.body_yaw_offset_label, wrapper_body_yaw_offset_label)


                items.body_yaw_offset = config_system.push(
                    'Builder', hash 'body_yaw_offset', menu.new(
                        ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n Offset', hash 'body_yaw_offset'), -180, 180, 0, true, 'Â°'
                    )
                )

                items.freestanding_body_yaw = config_system.push(
                    'Builder', hash 'freestanding_body_yaw', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key(
                            'Freestanding body yaw', hash 'freestanding_body_yaw'
                        )
                    )
                )

                if state ~= 'Fakelag' then
                    local wrapper_delay_from_label = theme_controller.wrap(new_key('Delay ${â€¢}', hash 'delay'))

                    items.delay_from_label = menu.new(
                        ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_delay_from_label()
                    )

                    theme_controller.push(items.delay_from_label, wrapper_delay_from_label)

                    items.delay_from = config_system.push(
                        'Builder', hash 'delay_from', menu.new(
                            ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n Delay', hash 'delay'), 1, 11, 1, true, 't', 1, {
                                [1] = 'Off',
                                [11] = 'Random'
                            }
                        )
                    )

                    local wrapper_delay_to_label = theme_controller.wrap(new_key('Delay ${â€¢}', hash 'delay_second'))

                    items.delay_to_label = menu.new(
                        ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_delay_to_label()
                    )

                    theme_controller.push(items.delay_to_label, wrapper_delay_to_label)

                    items.delay_to = config_system.push(
                        'Builder', hash 'delay_to', menu.new(
                            ui.new_slider, 'AA', 'Anti-aimbot angles', new_key('\n Delay', hash 'delay_second'), 0, 10, 0, true, 't', 1, {
                                [0] = 'Off',
                            }
                        )
                    )
                end

                return items
            end

            local function get_current_state()
                return string.format(
                    'State  \a%s~  ${%s}',
                    lock_clr(),
                    current_state
                )
            end

            local petarda = theme_controller.wrap(new_key(
                get_current_state(),
                'builder'
            ))

            builder.state_label = menu.new(
                ui.new_label, 'AA', 'Anti-aimbot angles', petarda()
            )

            theme_controller.push(builder.state_label, petarda)

            builder.state = menu.new(
                ui.new_combobox, 'AA', 'Anti-aimbot angles', new_key('\n State', 'builder'), conditions
            )

            for i = 1, #conditions do
                local state = conditions[i]

                local items = { }

                items.angles = create_builder_items(
                    state, nil
                )

                if state ~= 'Fakelag' then
                    items.defensive = create_defensive_items(state)
                end

                builder[state] = items
            end

            local callbacks do
                local function get_current_state_clr()
                    return string.format(
                        'State  \a%s~\a%s  %s',
                        lock_clr(),
                        reference.get_color(true),
                        current_state
                    )
                end

                local function on_element_update(items)
                    local value = items:get()

                    current_state = value

                    builder.state_label:set(get_current_state_clr())
                end

                builder.state:set_callback(on_element_update, true)
            end
        end

        local features = { } do
            antiaim.features = features

            local HOTKEY_MODE = {
                [0] = 'Always on',
                [1] = 'On hotkey',
                [2] = 'Toggle',
                [3] = 'Off hotkey'
            }

            local function get_hotkey_value(_, mode, key)
                return HOTKEY_MODE[mode], key or 0
            end

            local avoid_backstab = { } do
                features.avoid_backstab = avoid_backstab

                avoid_backstab.checkbox = config_system.push(
                    'Features', 'avoid_backstab.enabled', menu.new(
                        ui.new_checkbox, 'AA', 'Fake lag', new_key('Avoid backstab', 'avoid_backstab')
                    )
                )

                avoid_backstab.distance = config_system.push(
                    'Features', 'avoid_backstab.distance', menu.new(
                        ui.new_slider, 'AA', 'Fake lag', new_key('\n Distance', 'avoid_backstab'), 150, 320, 240, true, 'u'
                    )
                )

                avoid_backstab.separator = menu.new(
                    ui.new_label, 'AA', 'Fake lag', new_key('\n Separator', 'avoid_backstab')
                )
            end

            features.vanish = config_system.push(
                'Rage', 'warmup_round_end.select', menu.new(
                    ui.new_multiselect, 'AA', 'Fake Lag', new_key('Vanish Mode', 'warmup_round_end'), {"On Warmup", "No Enemies"}
                )
            )

            local manual_yaw = { } do
                features.manual_yaw = manual_yaw

                manual_yaw.checkbox = config_system.push(
                    'Features', 'manual_yaw.checkbox', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Manual Yaw', 'manual_yaw')
                    )
                )

                manual_yaw.options = config_system.push(
                    'Features', 'manual_yaw.options', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('\n Options', 'manual_yaw'), {
                            'Disable yaw modifiers',
                            'Freestanding body',
                            'Spam manuals'
                        }
                    )
                )

                local wrapper_forward_label = theme_controller.wrap(new_key('Forward  ${î„Œ}', 'manual_yaw'))

                manual_yaw.forward_label = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_forward_label()
                )

                theme_controller.push(manual_yaw.forward_label, wrapper_forward_label)

                manual_yaw.forward = config_system.push(
                    'Features', 'manual_yaw.forward', menu.new(
                        ui.new_hotkey, 'AA', 'Anti-aimbot angles', new_key('Forward', 'manual_yaw'), true
                    )
                )

                local wrapper_left_label = theme_controller.wrap(new_key('Left  ${î„Œ}', 'manual_yaw'))

                manual_yaw.left_label = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_left_label()
                )

                theme_controller.push(manual_yaw.left_label, wrapper_left_label)

                manual_yaw.left = config_system.push(
                    'Features', 'manual_yaw.left', menu.new(
                        ui.new_hotkey, 'AA', 'Anti-aimbot angles', new_key('Left', 'manual_yaw'), true
                    )
                )

                manual_yaw.left:set 'On hotkey'

                local wrapper_right_label = theme_controller.wrap(new_key('Right  ${î„Œ}', 'manual_yaw'))

                manual_yaw.right_label = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_right_label()
                )

                theme_controller.push(manual_yaw.right_label, wrapper_right_label)

                manual_yaw.right = config_system.push(
                    'Features', 'manual_yaw.right', menu.new(
                        ui.new_hotkey, 'AA', 'Anti-aimbot angles', new_key('Right', 'manual_yaw'), true
                    )
                )

                manual_yaw.right:set 'On hotkey'

                local wrapper_reset_label = theme_controller.wrap(new_key('Reset  ${î„Œ}', 'manual_yaw'))

                manual_yaw.reset_label = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_reset_label()
                )

                theme_controller.push(manual_yaw.reset_label, wrapper_reset_label)

                manual_yaw.reset = config_system.push(
                    'Features', 'manual_yaw.reset', menu.new(
                        ui.new_hotkey, 'AA', 'Anti-aimbot angles', new_key('Reset', 'manual_yaw'), true
                    )
                )

                manual_yaw.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', new_key('\n Separator', 'manual_yaw')
                )

                manual_yaw.reset:set 'On hotkey'

                manual_yaw.left:set 'Toggle'
                manual_yaw.right:set 'Toggle'
                manual_yaw.forward:set 'Toggle'
            end

            local freestanding = { } do
                features.freestanding = freestanding

                freestanding.checkbox = config_system.push(
                    'Features', 'freestanding.checkbox', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Freestanding', 'freestanding')
                    )
                )

                freestanding.hotkey = config_system.push(
                    'Features', 'freestanding.hotkey', menu.new(
                        ui.new_hotkey, 'AA', 'Anti-aimbot angles', new_key('Hotkey', 'freestanding'), true
                    )
                )

                freestanding.disablers = config_system.push(
                    'Features', 'freestanding.disablers', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('\n Disablers', 'freestanding'), {
                            'Standing',
                            'Moving',
                            'Slow Walk',
                            'Crouching',
                            'Air'
                        }
                    )
                )

                freestanding.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', new_key('\n Separator', 'freestanding')
                )
            end

            local edge_yaw = { } do
                features.edge_yaw = edge_yaw

                edge_yaw.checkbox = config_system.push(
                    'Features', 'edge_yaw.checkbox', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Edge Yaw', 'edge_yaw')
                    )
                )

                edge_yaw.hotkey = config_system.push(
                    'Features', 'edge_yaw.hotkey', menu.new(
                        ui.new_hotkey, 'AA', 'Anti-aimbot angles', new_key('Hotkey', 'edge_yaw'), true
                    )
                )

                edge_yaw.disablers = config_system.push(
                    'Features', 'edge_yaw.disablers', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('\n Disablers', 'edge_yaw'), {
                            'Standing',
                            'Moving',
                            'Slow Walk',
                            'Crouching',
                            'Air'
                        }
                    )
                )

                edge_yaw.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', new_key('\n Separator', 'edge_yaw')
                )
            end

            local break_lc_triggers = { } do
                features.break_lc_triggers = break_lc_triggers

                break_lc_triggers.checkbox = config_system.push(
                    'Features', 'break_lc_triggers.checkbox', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', 'Break LC triggers'
                    )
                )

                break_lc_triggers.states = config_system.push(
                    'Features', 'break_lc_triggers.states', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('\n States', 'force_break_lc_triggers'), {
                            'Flashed',
                            'Reloading',
                            'Taking damage'
                        }
                    )
                )

                break_lc_triggers.separator = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', new_key('\n Separator', 'force_break_lc_triggers')
                )

                lock_unselection(break_lc_triggers.states)
            end

            local safe_head = { } do
                features.safe_head = safe_head

                safe_head.checkbox = config_system.push(
                    'Features', 'safe_head.checkbox', menu.new(
                        ui.new_checkbox, 'AA', 'Anti-aimbot angles', new_key('Safe Head', 'safe_head')
                    )
                )

                safe_head.conditions = config_system.push(
                    'Features', 'safe_head.conditions', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('\n Conditions', 'safe_head'), {
                            'Standing',
                            'Crouch',
                            'Air crouch',
                            'Air crouch knife',
                            'Air crouch taser',
                            'Distance'
                        }
                    )
                )

                local wrapper_options_label = theme_controller.wrap(new_key('Options  ${~}', 'manual_yaw'))

                safe_head.options_label = menu.new(
                    ui.new_label, 'AA', 'Anti-aimbot angles', wrapper_options_label()
                )

                theme_controller.push(safe_head.options_label, wrapper_options_label)

                safe_head.options = config_system.push(
                    'Features', 'safe_head.options', menu.new(
                        ui.new_multiselect, 'AA', 'Anti-aimbot angles', new_key('\n Options', 'safe_head'), {'E Spam while active'}
                    )
                )
            end

            local fakelag = { } do
                features.fakelag = fakelag

                fakelag.checkbox = config_system.push(
                    'Features', 'fakelag.checkbox', menu.new(
                        ui.new_checkbox, 'AA', 'Other', new_key('Fake lag', 'fakelag')
                    )
                )

                fakelag.hotkey = config_system.push(
                    'Features', 'fakelag.hotkey', menu.new(
                        ui.new_hotkey, 'AA', 'Other', new_key('Hotkey', 'fakelag'), true
                    )
                )

                fakelag.type = config_system.push(
                    'Features', 'fakelag.type', menu.new(
                        ui.new_combobox, 'AA', 'Other', new_key('\n Type', 'fakelag'), {
                            'Dynamic',
                            'Maximum',
                            'Fluctuate'
                        }
                    )
                )

                local wrapper_variance_label = theme_controller.wrap(new_key('Variance ${â€¢}', 'fakelag'))

                    fakelag.variance_label = menu.new(
                        ui.new_label, 'AA', 'Other', wrapper_variance_label()
                    )

                theme_controller.push(fakelag.variance_label, wrapper_variance_label)

                fakelag.variance = config_system.push(
                    'Features', 'fakelag.variance', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('\n Variance', 'fakelag'), 0, 100, 0, true, '%'
                    )
                )

                local wrapper_limit_label = theme_controller.wrap(new_key('Limit ${â€¢}', 'fakelag'))

                    fakelag.limit_label = menu.new(
                        ui.new_label, 'AA', 'Other', wrapper_limit_label()
                    )

                theme_controller.push(fakelag.limit_label, wrapper_limit_label)

                fakelag.limit = config_system.push(
                    'Features', 'fakelag.limit', menu.new(
                        ui.new_slider, 'AA', 'Other', new_key('\n Limit', 'fakelag'), 1, 15, 1, true, 't'
                    )
                )

                fakelag.separator = menu.new(
                    ui.new_label, 'AA', 'Other', new_key('\n Separator', 'fakelag')
                )

                fakelag.checkbox:set(ui.get(reference.antiaim.fake_lag.enabled[1]))
                fakelag.hotkey:set(get_hotkey_value(ui.get(reference.antiaim.fake_lag.enabled[2])))

                fakelag.type:set(ui.get(reference.antiaim.fake_lag.amount))

                fakelag.variance:set(ui.get(reference.antiaim.fake_lag.variance))
                fakelag.limit:set(ui.get(reference.antiaim.fake_lag.limit))
            end

            local slow_motion = { } do
                features.slow_motion = slow_motion

                slow_motion.checkbox = config_system.push(
                    'Features', 'slow_motion.checkbox', menu.new(
                        ui.new_checkbox, 'AA', 'Other', new_key('Slow Motion', 'slow_motion')
                    )
                )

                slow_motion.hotkey = config_system.push(
                    'Features', 'slow_motion.hotkey', menu.new(
                        ui.new_hotkey, 'AA', 'Other', new_key('Hotkey', 'slow_motion'), true
                    )
                )

                slow_motion.checkbox:set(ui.get(reference.antiaim.other.slow_motion[1]))
                slow_motion.hotkey:set(get_hotkey_value(ui.get(reference.antiaim.other.slow_motion[2])))
            end

            local osaa = { } do
                features.osaa = osaa

                osaa.checkbox = config_system.push(
                    'Features', 'osaa.checkbox', menu.new(
                        ui.new_checkbox, 'AA', 'Other', new_key('\aB6B665FFOn shot anti-aim', 'osaa')
                    )
                )

                osaa.hotkey = config_system.push(
                    'Features', 'osaa.hotkey', menu.new(
                        ui.new_hotkey, 'AA', 'Other', new_key('Hotkey', 'osaa'), true
                    )
                )

                osaa.checkbox:set(ui.get(reference.antiaim.other.on_shot_antiaim[1]))
                osaa.hotkey:set(get_hotkey_value(ui.get(reference.antiaim.other.on_shot_antiaim[2])))
            end

            local fake_peek = { } do
                features.fake_peek = fake_peek

                fake_peek.checkbox = config_system.push(
                    'Features', 'fake_peek.checkbox', menu.new(
                        ui.new_checkbox, 'AA', 'Other', new_key('\aB6B665FFFake peek', 'fake_peek')
                    )
                )

                fake_peek.hotkey = config_system.push(
                    'Features', 'fake_peek.hotkey', menu.new(
                        ui.new_hotkey, 'AA', 'Other', new_key('Hotkey', 'fake_peek'), true
                    )
                )

                fake_peek.checkbox:set(ui.get(reference.antiaim.other.fake_peek[1]))
                fake_peek.hotkey:set(get_hotkey_value(ui.get(reference.antiaim.other.fake_peek[2])))
            end

        end
    end

    local scene do
        local function set_antiaimbot_display(value)
            local items = reference.antiaim.angles

            local pitch_value = ui.get(items.pitch[1])
            local yaw_value = ui.get(items.yaw[1])
            local body_yaw_value = ui.get(items.body_yaw[1])

            local force = not value

            ui.set_visible(items.enabled, value)
            ui.set_visible(items.pitch[1], value)

            if pitch_value == 'Custom' or force then
                ui.set_visible(items.pitch[2], value)
            end

            ui.set_visible(items.yaw_base, value)
            ui.set_visible(items.yaw[1], value)

            if yaw_value ~= 'Off' or force then
                local yaw_jitter_value = ui.get(items.yaw_jitter[1])

                ui.set_visible(items.yaw[2], value)
                ui.set_visible(items.yaw_jitter[1], value)

                if yaw_jitter_value ~= 'Off' or force then
                    ui.set_visible(items.yaw_jitter[2], value)
                end
            end

            ui.set_visible(items.body_yaw[1], value)

            if body_yaw_value ~= 'Off' or force then
                if body_yaw_value ~= 'Opposite' or force then
                    ui.set_visible(items.body_yaw[2], value)
                end

                ui.set_visible(items.freestanding_body_yaw, value)
            end

            ui.set_visible(items.edge_yaw, value)

            ui.set_visible(items.freestanding[1], value)
            ui.set_visible(items.freestanding[2], value)

            ui.set_visible(items.roll, value)
        end

        local function set_fakelag_display(value)
            local items = reference.antiaim.fake_lag

            ui.set_visible(items.enabled[1], value)
            ui.set_visible(items.enabled[2], value)

            ui.set_visible(items.amount, value)
            ui.set_visible(items.limit, value)
            ui.set_visible(items.variance, value)
        end

        local function set_other_display(value)
            local items = reference.antiaim.other

            ui.set_visible(items.slow_motion[1], value)
            ui.set_visible(items.slow_motion[2], value)

            ui.set_visible(items.leg_movement, value)

            ui.set_visible(items.on_shot_antiaim[1], value)
            ui.set_visible(items.on_shot_antiaim[2], value)

            ui.set_visible(items.fake_peek[1], value)
            ui.set_visible(items.fake_peek[2], value)
        end

        local function update_builder_items(items)
            local angles = items.angles
            local defensive = items.defensive

            if angles ~= nil then
                if angles.enabled ~= nil then
                    menu_logic.set(angles.enabled, true)

                    if not angles.enabled:get() then
                        return
                    end
                end

                if angles.bomb_e_fix ~= nil then
                    menu_logic.set(angles.bomb_e_fix, true)
                end

                if angles.pitch_type ~= nil then
                    menu_logic.set(angles.pitch_type, true)
                end

                if angles.yaw_type_label ~= nil then
                    menu_logic.set(angles.yaw_base_label, true)
                end

                if angles.yaw_type ~= nil then
                    menu_logic.set(angles.yaw_base, true)
                    menu_logic.set(angles.yaw_type_label, true)
                    menu_logic.set(angles.yaw_type, true)

                    if angles.yaw_type:get() == '180' then
                        menu_logic.set(angles.yaw_180_offset_label, true)
                        menu_logic.set(angles.yaw_180_offset, true)
                        menu_logic.set(angles.yaw_random_label, true)
                        menu_logic.set(angles.yaw_random, true)
                        menu_logic.set(angles.separator, true)
                    end

                    if angles.yaw_type:get() == 'Left / Right' then
                        menu_logic.set(angles.separator, true)
                        menu_logic.set(angles.yaw_side_label, true)
                        menu_logic.set(angles.yaw_side, true)

                        if angles.yaw_side:get() == 'Left' then
                            menu_logic.set(angles.yaw_left_offset_label, true)
                            menu_logic.set(angles.yaw_left_offset, true)

                            menu_logic.set(angles.yaw_left_random_label, true)
                            menu_logic.set(angles.yaw_left_random, true)

                            for i = 1, 3 do
                                local list = angles.yaw_left_delay[i]

                                if list == nil then
                                    break
                                end

                                menu_logic.set(list.label, true)
                                menu_logic.set(list.delay, true)

                                local min_value = (i == 1) and 1 or 0

                                if list.delay:get() <= min_value then
                                    break
                                end
                            end
                        end

                        if angles.yaw_side:get() == 'Right' then
                            menu_logic.set(angles.yaw_right_offset_label, true)
                            menu_logic.set(angles.yaw_right_offset, true)

                            menu_logic.set(angles.yaw_right_random_label, true)
                            menu_logic.set(angles.yaw_right_random, true)

                            for i = 1, 3 do
                                local list = angles.yaw_right_delay[i]

                                if list == nil then
                                    break
                                end

                                menu_logic.set(list.label, true)
                                menu_logic.set(list.delay, true)

                                local min_value = (i == 1) and 1 or 0

                                if list.delay:get() <= min_value then
                                    break
                                end
                            end
                        end
                    end
                end

                if angles.yaw_jitter ~= nil then
                    menu_logic.set(angles.yaw_jitter_label, true)
                    menu_logic.set(angles.yaw_jitter, true)

                    if angles.yaw_jitter:get() ~= 'Off' then
                        menu_logic.set(angles.jitter_offset_label, true)
                        menu_logic.set(angles.jitter_offset, true)

                        menu_logic.set(angles.jitter_random_label, true)
                        menu_logic.set(angles.jitter_random, true)

                        menu_logic.set(angles.separator2, true)
                    end

                    if angles.yaw_jitter:get() == 'X-way' then
                        menu_logic.set(angles.jitter_x_way_label, true)
                        menu_logic.set(angles.jitter_x_way, true)

                        menu_logic.set(angles.x_way_ways_label, true)
                        menu_logic.set(angles.x_way_ways, true)

                        if angles.jitter_x_way:get() == 'Custom' then
                            menu_logic.set(angles.x_way_offset_1_label, true)
                            menu_logic.set(angles.x_way_offset_1, true)

                            menu_logic.set(angles.x_way_offset_2_label, true)
                            menu_logic.set(angles.x_way_offset_2, true)

                            menu_logic.set(angles.x_way_offset_3_label, true)
                            menu_logic.set(angles.x_way_offset_3, true)

                            if angles.x_way_ways:get() >= 4 then
                                menu_logic.set(angles.x_way_offset_4_label, true)
                                menu_logic.set(angles.x_way_offset_4, true)
                            end

                            if angles.x_way_ways:get() == 5 then
                                menu_logic.set(angles.x_way_offset_5_label, true)
                                menu_logic.set(angles.x_way_offset_5, true)
                            end
                        end

                        menu_logic.set(angles.separator2, true)
                    end
                end

                if angles.body_yaw ~= nil then
                    menu_logic.set(angles.body_yaw_label, true)
                    menu_logic.set(angles.body_yaw, true)

                    if angles.body_yaw:get() ~= 'Off' then
                        if angles.body_yaw:get() ~= 'Opposite' then
                            menu_logic.set(angles.body_yaw_offset_label, true)
                            menu_logic.set(angles.body_yaw_offset, true)
                        end

                        local is_jitter = (
                            angles.body_yaw:get() == 'Jitter'
                            or angles.body_yaw:get() == 'Jitter Random'
                        )

                        if is_jitter then
                            menu_logic.set(angles.delay_from_label, true)
                            menu_logic.set(angles.delay_from, true)

                            if angles.delay_from:get() > 1 and angles.delay_from:get() ~= 11 then
                                menu_logic.set(angles.delay_to_label, true)
                                menu_logic.set(angles.delay_to, true)
                            end
                        else
                            menu_logic.set(angles.freestanding_body_yaw, true)
                        end
                    end
                end
            end

            if defensive ~= nil then
                if defensive.force_defensive ~= nil then
                    menu_logic.set(defensive.force_defensive, true)
                end

                menu_logic.set(defensive.enabled, true)

                if defensive.enabled:get() then
                    menu_logic.set(defensive.type, true)
                    menu_logic.set(defensive.pitch_label, true)
                    menu_logic.set(defensive.pitch, true)

                    if defensive.pitch:get() ~= 'Off' then
                        menu_logic.set(defensive.pitch_offset_label, true)
                        menu_logic.set(defensive.pitch_offset_1, true)

                        if defensive.pitch:get() ~= 'Static' then
                            menu_logic.set(defensive.pitch_offset_label, false)
                            menu_logic.set(defensive.pitch_label_1, true)
                            menu_logic.set(defensive.pitch_label_2, true)

                            menu_logic.set(defensive.pitch_offset_2, true)
                        end

                        if defensive.pitch:get() == 'Switch' then
                            menu_logic.set(defensive.pitch_offset_label, false)
                            menu_logic.set(defensive.pitch_offset_delay_label, true)
                            menu_logic.set(defensive.pitch_offset_delay, true)
                        end

                        if defensive.pitch:get() == 'Spin' then
                            menu_logic.set(defensive.pitch_offset_label, false)
                            menu_logic.set(defensive.pitch_offset_speed_label, true)
                            menu_logic.set(defensive.pitch_offset_speed, true)
                        end
                    end

                    if defensive.type:get() == 'Flick' then
                        menu_logic.set(defensive.yaw_offset_flick, true)
                        menu_logic.set(defensive.yaw_offset_flick_label, true)
                    end

                    if defensive.type:get() ~= 'Flick' then
                        menu_logic.set(defensive.yaw, true)

                        if defensive.yaw:get() ~= 'Off' then
                            local yaw = defensive.yaw:get()

                            local is_not_double =
                                yaw == 'Static'
                                or yaw == 'Spin'

                            if is_not_double then
                                menu_logic.set(defensive.yaw_offset_label, true)
                                menu_logic.set(defensive.yaw_offset, true)
                            end

                            if not is_not_double then
                                menu_logic.set(defensive.yaw_label_1, true)
                                menu_logic.set(defensive.yaw_label_2, true)

                                menu_logic.set(defensive.yaw_offset_1, true)
                                menu_logic.set(defensive.yaw_offset_2, true)

                                if yaw == 'Switch' then
                                    menu_logic.set(defensive.yaw_offset_delay_label, true)
                                    menu_logic.set(defensive.yaw_offset_delay, true)
                                end
                            end
                        end
                    end
                end
            end
        end

        local function force_update_scene()
            menu_logic.set(category_selector.script_name, true)
            menu_logic.set(category_selector.categories_label, true)
            menu_logic.set(category_selector.categories, true)

            local category = category_selector.categories:get()
            local home_tab = home.selector.tab:get()
            local home_antiaim = antiaim.selector.tab:get()

            if category == 'Home' then
                local ref = home.selector
                menu_logic.set(ref.separator, true)
                menu_logic.set(ref.tab_label, true)
                menu_logic.set(ref.tab, true)
                menu_logic.set(ref.separator2, true)

                local is_local = ref.tab:get() == 'Local' do
                    local ref = home.config_local

                    if is_local then
                        menu_logic.set(ref.welcome.user, true)
                        menu_logic.set(ref.welcome.build, true)
                    end
                end
            end


            if category == 'Anti-Aim' then
                local ref = antiaim.selector

                menu_logic.set(ref.separator, true)
                menu_logic.set(ref.tab_label, true)
                menu_logic.set(ref.tab, true)
                menu_logic.set(ref.separator2, true)

                -- Builder tab intentionally left empty.
                if home_antiaim == 'Builder' then
                end

                -- Features tab intentionally left empty.
                if home_antiaim == 'Features' then
                end
            end
        end

        local function on_shutdown()
            set_antiaimbot_display(true)
            set_fakelag_display(true)
            set_other_display(true)
        end

        local function on_paint_ui()
            set_antiaimbot_display(false)
            set_fakelag_display(false)
            set_other_display(false)
        end

        local logic_events = menu_logic.get_event_bus() do
            logic_events.update:set(force_update_scene)

            force_update_scene()
            menu_logic.force_update()
        end

        client.set_event_callback('shutdown', on_shutdown)
        client.set_event_callback('paint_ui', on_paint_ui)
    end
end

local config = { } do
    local ref = menu_elements.home.config_local

    local DB_NAME = '##CHERNOBYL_DB'
    local DB_DEFAULT = { }

    local db_data = (
        localdb['config']
        or database.read(DB_NAME)
        or DB_DEFAULT
    )

    local config_data = { }
    local config_list = { }

    local config_defaults = {
        [1] = {
            name = 'Default',
            data = 'chernobyl_133sqtr32==_',
            author = 'chernobyl',
            date = 'private'
        }
    }

    local function lock_clr()
        return utils.to_hex(75, 75, 75, 255)
    end

    local function def_clr()
        return utils.to_hex(200, 200, 200, 255)
    end

    local function get_current_date()
        local unix_time = client.unix_time()
        local days_since_epoch = math.floor(unix_time / 86400)
        local year = 1970
        local month = 1
        local day = 1

        local days_in_month = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}

        local function is_leap_year(y)
            return (y % 4 == 0 and y % 100 ~= 0) or (y % 400 == 0)
        end

        local remaining_days = days_since_epoch

        while remaining_days >= 365 do
            local days_in_year = is_leap_year(year) and 366 or 365

            if remaining_days >= days_in_year then
                remaining_days = remaining_days - days_in_year
                year = year + 1
            else
                break
            end
        end

        while remaining_days > 0 do
            local days_this_month = days_in_month[month]

            if month == 2 and is_leap_year(year) then
                days_this_month = 29
            end

            if remaining_days >= days_this_month then
                remaining_days = remaining_days - days_this_month
                month = month + 1
                if month > 12 then
                    month = 1
                    year = year + 1
                end
            else
                day = remaining_days + 1
                break
            end
        end

        return string.format("%02d.%02d.%04d", day, month, year)
    end

    local function get_current_author()
        return script.user
    end

    local function update_config_info_ui(config_info)
        local author_label = string.format(
            '\a%s%s \a%s~  \a%sAuthor \a%s| \a%s%s',
            reference.get_color(true),
            'î„½',
            lock_clr(),
            def_clr(),
            lock_clr(),
            reference.get_color(true),
            config_info.author or 'Unknown'
        )

        local date_label = string.format(
            '\a%s%s \a%s~  \a%sCreated at \a%s| \a%s%s',
            reference.get_color(true),
            'î„¡',
            lock_clr(),
            def_clr(),
            lock_clr(),
            reference.get_color(true),
            config_info.date or 'Unknown'
        )

        ref.author:set(author_label)
        ref.data:set(date_label)
    end

    local function clear_config_info_ui()
        local empty_author = string.format(
            '\a%s%s \a%s~  \a%sAuthor \a%s| \a%s%s',
            reference.get_color(true),
            'î„½',
            lock_clr(),
            def_clr(),
            lock_clr(),
            reference.get_color(true),
            'None'
        )

        local empty_date = string.format(
            '\a%s%s \a%s~  \a%sCreated at \a%s| \a%s%s',
            reference.get_color(true),
            'î„¡',
            lock_clr(),
            def_clr(),
            lock_clr(),
            reference.get_color(true),
            'None'
        )

        ref.author:set(empty_author)
        ref.data:set(empty_date)
    end

    for i = 1, #db_data do
        config_data[i] = db_data[i]

        if config_data[i].author == nil then
            config_data[i].author = "Unknown"
        end

        if config_data[i].date == nil then
            config_data[i].date = "Unknown"
        end
    end

    for i = #config_defaults, 1, -1 do
        local list = config_defaults[i]

        if list.data == nil then
            goto continue
        end

        local ok, result = config_system.decode(list.data)

        if not ok then
            -- config is not valid, delete it
            table.remove(config_defaults, i)
            goto continue
        end

        list.data = result

        ::continue::
    end

    local function create_config(name, data, is_default, author, date)
        local list = { }

        list.name = name
        list.data = data
        list.default = is_default
        list.author = author or "Unknown"
        list.date = date or "Unknown"

        return list
    end

    local function find_config(name)
        for i = 1, #config_list do
            local data = config_list[i]

            if data.name == name then
                return data, i
            end
        end

        return nil, -1
    end

    local function save_config_data()
        localdb['config'] = config_data
    end

    local function update_config_list()
        for i = 1, #config_list do
            config_list[i] = nil
        end

        for i = 1, #config_defaults do
            local list = config_defaults[i]

            local cell = create_config(
                list.name,
                list.data,
                true,
                list.author,
                list.date
            )

            table.insert(config_list, cell)
        end

        for i = 1, #config_data do
            local list = config_data[i]

            local cell = create_config(
                list.name,
                list.data,
                false,
                list.author,
                list.date
            )

            cell.data_index = i

            table.insert(config_list, cell)
        end
    end

    local function get_render_list()
        local result = { }

        for i = 1, #config_list do
            local list = config_list[i]

            local name = list.name

            if list.default then
                name = string.format('%s*', name)
            end

            table.insert(result, name)
        end

        return result
    end

    local function load_config(name, categories)
        local list, idx = find_config(name)

        if list == nil or idx == -1 then
            return
        end

        local ok, result = config_system.import(
            list.data, categories
        )

        if not ok then
            logging.error(string.format(
                'failed to import %s config: %s', name, result
            ))
            return
        end

        logging.success(string.format(
            'loaded %s config', name
        ))

        update_config_info_ui(list)
    end

    local function save_config(name)
        --windows.save_settings()

        local cfg_data = config_system.export()
        local current_author = get_current_author()
        local current_date = get_current_date()

        local list, idx = find_config(name)

        if list == nil or idx == -1 then
            table.insert(config_data, {
                name = name,
                data = cfg_data,
                author = current_author,
                date = current_date
            })

            save_config_data()
            update_config_list()

            ref.list:update(get_render_list())

            logging.success(string.format(
                'created %s config', name
            ))

            return
        end

        if list.default then
            logging.error(string.format(
                'you can\'t edit %s config', name
            ))
            return
        end

        list.data = cfg_data
        list.date = current_date

        if list.data_index ~= nil then
            local data_cell = config_data[list.data_index]

            if data_cell ~= nil then
                data_cell.data = cfg_data
                data_cell.date = current_date
            end
        end

        save_config_data()
        update_config_list()

        logging.success(string.format(
            'saved %s config', name
        ))
    end

    local function delete_config(name)
        local list, idx = find_config(name)

        if list == nil or idx == -1 then
            return
        end

        if list.default then
            logging.error(string.format(
                'you can\'t delete %s config', name
            ))
            return
        end

        local data_index = list.data_index

        if data_index == nil then
            return
        end

        table.remove(config_data, data_index)

        save_config_data()
        update_config_list()

        ref.list:update(get_render_list())

        local next_input = ''

        local index = math.min(
            ref.list:get() + 1,
            #config_list
        )

        local data = config_list[index]

        if data ~= nil then
            next_input = data.name
        end

        ref.input:set(next_input)

        logging.success(string.format(
            'deleted %s config', name
        ))

        clear_config_info_ui()
    end

    local callbacks do
        local function on_list(item)
            local index = item:get()

            if index == nil then
                return
            end

            local list = config_list[index + 1]

            if list == nil then
                clear_config_info_ui()
                return
            end

            ref.input:set(list.name)

            update_config_info_ui(list)
        end

        local function on_load()
            local name = utils.trim(
                ref.input:get()
            )

            if name == '' then
                return
            end

            load_config(name)
        end

        local function on_save()
            local name = utils.trim(
                ref.input:get()
            )

            if name == '' then
                return
            end

            save_config(name)
        end

        local function on_delete()
            local name = utils.trim(
                ref.input:get()
            )

            if name == '' then
                return
            end

            delete_config(name)
        end

        local function on_export()
            --windows.save_settings()

            local ok, result = config_system.encode(
                config_system.export()
            )

            if not ok then
                return
            end

            clipboard.set(result)

            logging.success(
                'exported config with metadata'
            )
        end

        local function on_import()
            local str = clipboard.get()

            if str == nil then
                return
            end

            local ok, result = config_system.decode(str)

            if not ok then
                return
            end

            config_system.import(result)

            --windows.load_settings()

            logging.success(
                'imported config'
            )
        end

        ref.list:set_callback(on_list)

        ref.load:set_callback(on_load)
        ref.save:set_callback(on_save)
        ref.delete:set_callback(on_delete)

        ref.export:set_callback(on_export)
        ref.import:set_callback(on_import)
    end

    update_config_list()

    ref.list:update(get_render_list())

    clear_config_info_ui()
end

local antiaim do
    local buffer = { } do
        local ref = reference.antiaim.angles

        local function override_value(item, ...)
            if ... == nil then
                return
            end

            override.set(item, ...)
        end

        local Buffer = { } do
            Buffer.__index = Buffer

            function Buffer:clear()
                for k in pairs(self) do
                    self[k] = nil
                end
            end

            function Buffer:copy(target)
                for k, v in pairs(target) do
                    self[k] = v
                end
            end

            function Buffer:unset()
                override.unset(ref.roll)

                override.unset(ref.freestanding[2])
                override.unset(ref.freestanding[1])

                override.unset(ref.edge_yaw)

                override.unset(ref.freestanding_body_yaw)

                override.unset(ref.body_yaw[2])
                override.unset(ref.body_yaw[1])

                override.unset(ref.yaw[2])
                override.unset(ref.yaw[1])

                override.unset(ref.yaw_jitter[2])
                override.unset(ref.yaw_jitter[1])

                override.unset(ref.yaw_base)

                override.unset(ref.pitch[2])
                override.unset(ref.pitch[1])

                override.unset(ref.enabled)
            end

            function Buffer:set()
                if self.pitch_offset ~= nil then
                    self.pitch_offset = utils.clamp(
                        self.pitch_offset, -89, 89
                    )
                end

                if self.yaw_offset ~= nil then
                    self.yaw_offset = utils.normalize(
                        self.yaw_offset, -180, 180
                    )
                end

                if self.jitter_offset ~= nil then
                    self.jitter_offset = utils.normalize(
                        self.jitter_offset, -180, 180
                    )
                end

                if self.body_yaw_offset ~= nil then
                    self.body_yaw_offset = utils.clamp(
                        self.body_yaw_offset, -180, 180
                    )
                end

                override_value(ref.enabled, self.enabled)

                override_value(ref.pitch[1], self.pitch)
                override_value(ref.pitch[2], self.pitch_offset)

                override_value(ref.yaw_base, self.yaw_base)

                override_value(ref.yaw[1], self.yaw)
                override_value(ref.yaw[2], self.yaw_offset)

                override_value(ref.yaw_jitter[1], self.yaw_jitter)
                override_value(ref.yaw_jitter[2], self.jitter_offset)

                override_value(ref.body_yaw[1], self.body_yaw)
                override_value(ref.body_yaw[2], self.body_yaw_offset)

                override_value(ref.freestanding_body_yaw, self.freestanding_body_yaw)

                override_value(ref.edge_yaw, self.edge_yaw)

                if self.freestanding == true then
                    override_value(ref.freestanding[1], true)
                    override_value(ref.freestanding[2], 'Always on')
                elseif self.freestanding == false then
                    override_value(ref.freestanding[1], false)
                    override_value(ref.freestanding[2], 'On hotkey')
                end

                override_value(ref.roll, self.roll)
            end
        end

        setmetatable(buffer, Buffer)
    end

    local buffer_mods = { } do
        local inverts = 0
        local yaw_inverts = 0

        local inverted = false
        local yaw_inverted = false

        local delay_ticks = 0
        local yaw_delay_ticks = 0

        local skitter = {
            -1, 1, 0,
            -1, 1, 0,
            -1, 0, 1,
            -1, 0, 1
        }

        function buffer_mods:get_yaw_inverted()
            return yaw_inverted
        end

        function buffer_mods:get_yaw_inverts()
            return yaw_inverts
        end

        function buffer_mods:update_inverter()
            if exploit.get().shift then
                local delay = math.max(
                    1, buffer.delay or 1
                )

                delay_ticks = delay_ticks + 1

                if delay_ticks < delay then
                    return
                end
            end

            local should_invert = true

            if buffer.body_yaw == 'Jitter Random' then
                should_invert = utils.random_int(0, 1) == 0
            end

            inverts = inverts + 1

            if should_invert then
                inverted = not inverted
            end

            delay_ticks = 0
        end

        function buffer_mods:update_yaw_delay()
            if exploit.get().shift then
                local delay = 1

                local yaw_left_delay = nil
                local yaw_right_delay = nil

                if buffer.yaw_left_delay ~= nil or buffer.yaw_right_delay ~= nil then
                    yaw_left_delay = buffer.yaw_left_delay or 1
                    yaw_right_delay = buffer.yaw_right_delay or 1
                end

                if yaw_inverted and yaw_left_delay ~= nil then
                    delay = yaw_left_delay
                end

                if not yaw_inverted and yaw_right_delay ~= nil then
                    delay = yaw_right_delay
                end

                yaw_delay_ticks = yaw_delay_ticks + 1

                if yaw_delay_ticks < delay then
                    return
                end
            end

            yaw_inverts = yaw_inverts + 1
            yaw_inverted = not yaw_inverted

            yaw_delay_ticks = 0
        end

        function buffer_mods:update_yaw_offset()
            if buffer.yaw_left ~= nil and buffer.yaw_right ~= nil then
                local yaw = buffer.yaw_offset or 0

                if buffer.yaw_left_delay ~= nil or buffer.yaw_right_delay ~= nil then
                    local body_yaw_offset = math.abs(buffer.body_yaw_offset)

                    if not yaw_inverted then
                        yaw = yaw + buffer.yaw_left
                    end

                    if yaw_inverted then
                        yaw = yaw + buffer.yaw_right
                    end

                    if not yaw_inverted then
                        body_yaw_offset = -body_yaw_offset
                    end

                    buffer.body_yaw = 'Static'
                    buffer.body_yaw_offset = body_yaw_offset
                else
                    if buffer.body_yaw_offset < 0 then
                        yaw = yaw + buffer.yaw_left
                    end

                    if buffer.body_yaw_offset > 0 then
                        yaw = yaw + buffer.yaw_right
                    end
                end

                buffer.yaw_offset = yaw
            end

            if buffer.yaw_offset ~= nil then
                buffer.yaw_offset = wrappers.normalize_yaw(buffer.yaw_offset)
            end
        end

        function buffer_mods:update_yaw_jitter()
            local jitter_inverts = inverts
            local jitter_inverted = inverted

            if buffer.yaw_left_delay ~= nil or buffer.yaw_right_delay ~= nil then
                jitter_inverts = yaw_inverts
                jitter_inverted = yaw_inverted
            end

            if buffer.yaw_jitter == 'Offset' then
                local yaw = buffer.yaw_offset or 0
                local offset = buffer.jitter_offset

                buffer.yaw_jitter = 'Off'
                buffer.jitter_offset = 0

                buffer.yaw_offset = yaw + (jitter_inverted and offset or 0)

                return
            end

            if buffer.yaw_jitter == 'Center' then
                local yaw = buffer.yaw_offset or 0
                local offset = buffer.jitter_offset

                if not jitter_inverted then
                    offset = -offset
                end

                buffer.yaw_jitter = 'Off'
                buffer.jitter_offset = 0

                buffer.yaw_offset = yaw + offset / 2

                return
            end

            if buffer.yaw_jitter == 'Skitter' then
                local index = jitter_inverts % #skitter
                local multiplier = skitter[index + 1]

                local yaw = buffer.yaw_offset or 0
                local offset = buffer.jitter_offset

                buffer.yaw_jitter = 'Off'
                buffer.jitter_offset = 0

                buffer.yaw_offset = yaw + (offset * multiplier)

                return
            end

            if buffer.yaw_jitter == 'X-way' then
                local ctx = buffer.way

                if ctx ~= nil then
                    local yaw = buffer.yaw_offset or 0
                    local offset = buffer.jitter_offset

                    local index = jitter_inverts % ctx.count
                    local is_custom = ctx.offsets ~= nil

                    if is_custom then
                        buffer.yaw_offset = yaw + ctx.offsets[index + 1]
                    end

                    if not is_custom then
                        buffer.yaw_offset = yaw + utils.lerp(
                            -offset, offset, index / (ctx.count - 1)
                        )
                    end
                end

                buffer.yaw_jitter = 'Off'
                buffer.jitter_offset = 0

                return
            end
        end

        function buffer_mods:update_body_yaw()
            if buffer.body_yaw == 'Jitter' then
                local offset = buffer.body_yaw_offset

                if offset == 0 then
                    offset = 1
                end

                if not inverted then
                    offset = -offset
                end

                buffer.body_yaw = 'Static'
                buffer.body_yaw_offset = offset
            end

            if buffer.body_yaw == 'Jitter Random' then
                local offset = buffer.body_yaw_offset

                if offset == 0 then
                    offset = 1
                end

                buffer.body_yaw = 'Static'
                buffer.body_yaw_offset = inverted and offset or -offset
            end
        end
    end

    local defensive = { } do
        local function is_exploit_active()
            if reference.is_double_tap_active() then
                return true
            end

            if reference.is_on_shot_antiaim_active() then
                return true
            end

            return false
        end

        local default = { } do
            function default:update_pitch(buffer, items)
                local value = items.pitch:get()

                local pitch_offset_1 = items.pitch_offset_1:get()
                local pitch_offset_2 = items.pitch_offset_2:get()

                local pitch_offset_delay = items.pitch_offset_delay:get()
                local pitch_offset_speed = items.pitch_offset_speed:get()

                if value == 'Off' then
                    return
                end

                if value == 'Static' then
                    buffer.pitch = 'Custom'
                    buffer.pitch_offset = pitch_offset_1

                    return
                end

                if value == 'Switch' then
                    local delay = pitch_offset_delay

                    local offset = (localplayer.sent_packets % (delay * 2)) < delay
                        and pitch_offset_1 or pitch_offset_2

                    buffer.pitch = 'Custom'
                    buffer.pitch_offset = offset

                    return
                end

                if value == 'Spin' then
                    local time = globals.curtime() * (
                        pitch_offset_speed * 0.1
                    )

                    buffer.pitch = 'Custom'

                    buffer.pitch_offset = utils.lerp(
                        pitch_offset_1,
                        pitch_offset_2,
                        time % 1.0
                    )
                    return
                end

                if value == 'Random' then
                    buffer.pitch = 'Custom'

                    buffer.pitch_offset = utils.random_int(
                        pitch_offset_1, pitch_offset_2
                    )

                    return
                end
            end

            function default:update_yaw(buffer, items)
                local value = items.yaw:get()

                local yaw_offset = items.yaw_offset:get()

                local yaw_offset_1 = items.yaw_offset_1:get()
                local yaw_offset_2 = items.yaw_offset_2:get()

                if value == 'Off' then
                    return
                end

                buffer.freestanding = false

                buffer.yaw_left = 0
                buffer.yaw_right = 0

                buffer.yaw_offset = 0

                buffer.yaw_jitter = 'Off'
                buffer.jitter_offset = 0

                if value == 'Static' then
                    buffer.yaw = '180'
                    buffer.yaw_offset = yaw_offset

                    return
                end

                if value == 'Switch' then
                    local delay = items.yaw_offset_delay:get()

                    local offset = localplayer.sent_packets % (delay * 2) < delay
                        and yaw_offset_1 or yaw_offset_2

                    buffer.yaw = '180'
                    buffer.yaw_offset = offset

                    return
                end

                if value == 'Spin' then
                    local offset = globals.curtime() * (yaw_offset * 12) % 360

                    buffer.yaw = '180'
                    buffer.yaw_offset = offset

                    return
                end

                if value == 'Random' then
                    buffer.yaw = '180'

                    buffer.yaw_offset = utils.random_int(
                        yaw_offset_1, yaw_offset_2
                    )

                    return
                end
            end

            function default:update(cmd, buffer, items)
                self:update_pitch(buffer, items)
                self:update_yaw(buffer, items)
            end
        end

        local flick = { } do
            local freestand_side = 1

            local function get_angles(player, target)
                local player_origin = vector(entity.get_origin(player))
                local target_origin = vector(entity.get_origin(target))

                return vector((target_origin - player_origin):angles())
            end

            local function update_freestand(cmd)
                local me = entity.get_local_player()

                if me == nil then
                    return
                end

                local threat = client.current_threat()

                if threat == nil then
                    return
                end

                local angles = get_angles(me, threat)

                local eye_pos = vector(utils.get_eye_position(me))
                local stomach = vector(entity.hitbox_position(threat, 3))

                local forward_left = vector():init_from_angles(0, angles.y + 90)
                local forward_right = vector():init_from_angles(0, angles.y - 90)

                local point_left = eye_pos + forward_left * 31
                local point_right = eye_pos + forward_right * 31

                local ent_left, damage_left = client.trace_bullet(
                    me, point_left.x, point_left.y, point_left.z,
                    stomach.x, stomach.y, stomach.z, false
                )

                local ent_right, damage_right = client.trace_bullet(
                    me, point_right.x, point_right.y, point_right.z,
                    stomach.x, stomach.y, stomach.z, false
                )

                if ent_left ~= threat then
                    damage_left = 0
                end

                if ent_right ~= threat then
                    damage_right = 0
                end

                local should_update = (
                    (damage_left > 0 or damage_right > 0)
                    and damage_left ~= damage_right
                )

                if should_update then
                    freestand_side = (damage_left > damage_right) and -1 or 1
                end
            end

            function flick:update_yaw(buffer, items)
                buffer.yaw_base = 'At targets'

                buffer.yaw = '180'
                buffer.yaw_offset = items.yaw_offset_flick:get() * freestand_side

                buffer.yaw_left = 0
                buffer.yaw_right = 0

                buffer.yaw_jitter = 'Off'
                buffer.jitter_offset = 0
            end

            function flick:update_body_yaw(buffer, items)
                buffer.body_yaw = 'Static'
                buffer.body_yaw_offset = freestand_side

                buffer.freestanding_body_yaw = false
            end

            function flick:update(cmd, buffer, items)
                update_freestand(cmd)

                default:update_pitch(buffer, items)

                self:update_yaw(buffer, items)
                self:update_body_yaw(buffer, items)

                buffer.edge_yaw = false
                buffer.freestanding = false

                buffer.roll = 0
            end
        end

        function defensive:apply(cmd, items)
            if items.force_defensive ~= nil and items.force_defensive:get() then
                cmd.force_defensive = true
            end

            local is_duck_peek_active = reference.is_duck_peek_assist()

            if not is_exploit_active() or is_duck_peek_active then
                return false
            end

            local exploit_data = exploit.get()
            local defensive_data = exploit_data.defensive

            if defensive_data.left <= 0 then
                return
            end

            if not items.enabled:get() then
                return false
            end

            local buffer_ctx = { }

            if items.type:get() == 'Default' then
                default:update(cmd, buffer_ctx, items)
            end

            if items.type:get() == 'Flick' then
                flick:update(cmd, buffer_ctx, items)
            end

            buffer.defensive = buffer_ctx

            return true
        end
    end

    local builder = { } do
        local ref = menu_elements.antiaim.builder

        local RANDOM_YAW_DELAY_VALUE = 11

        local function update_yaw_base(items)
            if items.yaw_base == nil then
               return
            end

            local yaw_base = items.yaw_base:get()

            buffer.yaw_base = yaw_base
        end

        local function update_yaw(items)
            if items.yaw_type == nil then
                return
            end

            buffer.yaw_type = items.yaw_type:get()

            if buffer.yaw_type == '180' then
                buffer.yaw = '180'

                local yaw = items.yaw_180_offset:get()
                local random = items.yaw_random:get()

                if random > 0 then
                    yaw = yaw + utils.random_int(-random, random)
                end

                buffer.yaw_offset = yaw
            end

            if buffer.yaw_type == 'Left / Right' then
                buffer.yaw = '180'

                local yaw_left = items.yaw_left_offset:get()
                local yaw_right = items.yaw_right_offset:get()

                local random_left = items.yaw_left_random:get()
                local random_right = items.yaw_right_random:get()

                -- local delay_left = items.yaw_left_delay:get()
                -- local delay_right = items.yaw_right_delay:get()

                -- local delay_second_left = items.yaw_left_delay_second:get()
                -- local delay_second_right = items.yaw_right_delay_second:get()

                if random_left > 0 then
                    yaw_left = yaw_left + utils.random_int(-random_left, random_left)
                end

                if random_right > 0 then
                    yaw_right = yaw_right + utils.random_int(-random_right, random_right)
                end

                buffer.yaw_left = yaw_left
                buffer.yaw_right = yaw_right

                local left_delays = 0
                local right_delays = 0

                for i = 1, 3 do
                    local list = items.yaw_left_delay[i]

                    if list == nil then
                        break
                    end

                    local delay = list.delay:get()
                    local min_delay = i == 1 and 1 or 0

                    if delay <= min_delay then
                        break
                    end

                    left_delays = left_delays + 1
                end

                for i = 1, 3 do
                    local list = items.yaw_right_delay[i]

                    if list == nil then
                        break
                    end

                    local delay = list.delay:get()
                    local min_delay = i == 1 and 1 or 0

                    if delay <= min_delay then
                        break
                    end

                    right_delays = right_delays + 1
                end

                local left_delay = nil
                local right_delay = nil

                local yaw_inverts = buffer_mods:get_yaw_inverts()
                local yaw_stage = math.floor(yaw_inverts / 2)

                if left_delays > 0 then
                    local index = yaw_stage % left_delays
                    local list = items.yaw_left_delay[index + 1]

                    left_delay = list.delay:get()
                end

                if right_delays > 0 then
                    local index = yaw_stage % right_delays
                    local list = items.yaw_right_delay[index + 1]

                    right_delay = list.delay:get()
                end

                buffer.yaw_left_delay = left_delay
                buffer.yaw_right_delay = right_delay
            end
        end

        local function update_jitter(items)
            if items.yaw_jitter == nil then
                return
            end

            local yaw_jitter = items.yaw_jitter:get()
            local jitter_offset = items.jitter_offset:get()

            if yaw_jitter ~= 'Off' then
                local random = items.jitter_random:get() * 0.01
                local random_offset = jitter_offset * random

                jitter_offset = jitter_offset + utils.random_int(
                    -random_offset, random_offset
                )
            end

            buffer.yaw_jitter = yaw_jitter
            buffer.jitter_offset = jitter_offset

            if yaw_jitter == 'X-way' then
                local way_ctx = { }

                way_ctx.count = items.x_way_ways:get()

                if items.jitter_x_way:get() == 'Custom' then
                    local offsets = { }

                    for i = 1, way_ctx.count do
                        offsets[i] = items['x_way_offset_' .. i]:get()
                    end

                    way_ctx.offsets = offsets
                end

                buffer.way = way_ctx
            end
        end

        local function update_body_yaw(items)
            if items.body_yaw == nil then
                return
            end

            local body_yaw = items.body_yaw:get()
            local body_yaw_offset = items.body_yaw_offset:get()

            local freestanding_body_yaw = false

            if body_yaw ~= 'Jitter' and body_yaw ~= 'Jitter Random' then
                freestanding_body_yaw = items.freestanding_body_yaw:get()
            end

            buffer.body_yaw = body_yaw
            buffer.body_yaw_offset = body_yaw_offset

            buffer.freestanding_body_yaw = freestanding_body_yaw

            if items.delay_from ~= nil and items.delay_to ~= nil then
                local delay_from = items.delay_from:get()
                local delay_to = items.delay_to:get()

                buffer.delay = delay_from

                if delay_from > 1 and delay_to > 0 then
                    buffer.delay = utils.random_int(
                        delay_from, delay_to
                    )
                end
            end
        end

        function builder:get(state)
            local items = ref[state]

            if items == nil then
                return nil
            end

            return items
        end

        function builder:is_active_ex(items)
            local angles = items.angles

            if angles == nil then
                return false
            end

            return angles.enabled == nil
                or angles.enabled:get()
        end

        function builder:is_active(state)
            local items = self:get(state)

            if items == nil then
                return false
            end

            return self:is_active_ex(items)
        end

        function builder:apply_ex(items)
            if items == nil then
                return false
            end

            local angles = items.angles

            if angles == nil then
                return false
            end

            buffer.enabled = true

            buffer.pitch = 'Default'

            update_yaw_base(angles)
            update_yaw(angles)
            update_jitter(angles)
            update_body_yaw(angles)

            return true
        end

        function builder:apply(state)
            local items = self:get(state)

            if items == nil then
                return false, nil
            end

            if not self:is_active_ex(items) then
                return false, items
            end

            local angles = items.angles

            if angles == nil then
                return false
            end

            self:apply_ex(items)
            return true, items
        end

        function builder:update(cmd)
            local states = conditions.get()
            local state = states[#states]

            if state == nil then
                return false, nil, nil
            end

            local active, items = self:apply(
                state
            )

            if not active or items == nil then
                local _, new_items = self:apply(
                    'Shared'
                )

                if new_items ~= nil then
                    items = new_items
                    state = 'Shared'
                end
            end

            return true, items, state
        end
    end

    local fakelag_clone = { } do
        local ref = menu_elements.antiaim.features.fakelag

        local HOTKEY_MODE = {
            [0] = 'Always on',
            [1] = 'On hotkey',
            [2] = 'Toggle',
            [3] = 'Off hotkey'
        }

        local function get_hotkey_value(_, mode, key)
            return HOTKEY_MODE[mode], key or 0
        end

        function fakelag_clone:update()
            override.set(reference.antiaim.fake_lag.enabled[1], ref.checkbox:get())
            override.set(reference.antiaim.fake_lag.enabled[2], get_hotkey_value(ref.hotkey:get()))

            override.set(reference.antiaim.fake_lag.amount, ref.type:get())

            override.set(reference.antiaim.fake_lag.variance, ref.variance:get())
            override.set(reference.antiaim.fake_lag.limit, ref.limit:get())
        end

        function fakelag_clone:shutdown()
            override.unset(reference.antiaim.fake_lag.enabled[1])
            override.unset(reference.antiaim.fake_lag.enabled[2])

            override.unset(reference.antiaim.fake_lag.amount)

            override.unset(reference.antiaim.fake_lag.variance)
            override.unset(reference.antiaim.fake_lag.limit)
        end
    end

    local safe_head = { } do
        local ref = menu_elements.antiaim.features.safe_head

        local function should_update()
            return ref.checkbox:get()
        end

        local function get_condition(me, threat)
            local weapon = entity.get_player_weapon(me)

            if weapon == nil then
                return nil
            end

            local weapon_info = csgo_weapons(weapon)

            if weapon_info == nil then
                return nil
            end

            local weapon_type = weapon_info.type
            local weapon_index = weapon_info.idx

            -- fun fact: taser is also a knife type of weapon
            local is_knife = weapon_type == 'knife'
            local is_taser = weapon_index == 31

            local my_origin = vector(entity.get_origin(me))
            local threat_origin = vector(entity.get_origin(threat))

            local delta = threat_origin - my_origin

            local height = -delta.z
            local distancesqr = delta:length2dsqr()

            if localplayer.is_onground then
                local is_distance_state = not localplayer.is_moving
                    or localplayer.is_crouched

                if is_distance_state and height >= 10 and distancesqr > 1000 * 1000 then
                    return 'Distance'
                end

                if localplayer.is_crouched then
                    if height >= 48 then
                        return 'Crouch'
                    end
                else
                    if not localplayer.is_moving and height >= 24 then
                        return 'Standing'
                    end
                end

                return nil
            end

            if localplayer.is_crouched then
                if is_taser and height > -20 and distancesqr < 500 * 500 then
                    return 'Air crouch taser'
                end

                if is_knife  then
                    return 'Air crouch knife'
                end

                if height > 160 then
                    return 'Air crouch'
                end
            end

            return nil
        end

        local function update_buffer(condition)
            if condition == 'Air crouch knife' then
                buffer.pitch = 'Default'
                buffer.yaw_base = 'At targets'

                buffer.yaw = '180'
                buffer.yaw_offset = 37

                buffer.yaw_left = 0
                buffer.yaw_right = 0

                buffer.yaw_jitter = 'Off'
                buffer.jitter_offset = 0

                buffer.body_yaw = 'Static'
                buffer.body_yaw_offset = 1

                buffer.freestanding_body_yaw = false

                buffer.roll = 0
                buffer.defensive = nil

                return
            end

            buffer.pitch = 'Default'
            buffer.yaw_base = 'At targets'

            buffer.yaw = '180'
            buffer.yaw_offset = 0

            buffer.yaw_left = 0
            buffer.yaw_right = 0

            buffer.yaw_jitter = 'Off'
            buffer.jitter_offset = 0

            buffer.body_yaw = 'Static'
            buffer.body_yaw_offset = 0

            buffer.freestanding_body_yaw = false

            buffer.roll = 0
            buffer.defensive = nil
        end

        local function update_spam(cmd, condition)
            if not ref.options:get 'E Spam while active' then
                return
            end

            local buffer_ctx = { }

            buffer_ctx.pitch = 'Custom'
            buffer_ctx.pitch_offset = 0

            buffer_ctx.yaw = '180'
            buffer_ctx.yaw_offset = 180

            buffer_ctx.yaw_jitter = 'Off'
            buffer_ctx.jitter_offset = 0

            buffer_ctx.body_yaw = 'Static'
            buffer_ctx.body_yaw_offset = 180
            buffer_ctx.freestanding_body_yaw = false

            cmd.force_defensive = true

            buffer.defensive = buffer_ctx
        end

        function safe_head:update(cmd)
            if not should_update() then
                return false
            end

            local me = entity.get_local_player()

            if me == nil then
                return false
            end

            local threat = client.current_threat()

            if threat == nil  then
                return false
            end

            local condition = get_condition(me, threat)

            if condition == nil then
                return false
            end

            local is_enabled = ref.conditions:get(condition)

            if not is_enabled then
                return false
            end

            update_buffer(condition)
            update_spam(cmd, condition)

            return true
        end
    end

    local edge_yaw = { } do
        local ref = menu_elements.antiaim.features.edge_yaw

        local function get_state()
            if not localplayer.is_onground then
                return 'Air'
            end

            if localplayer.is_crouched then
                return 'Crouching'
            end

            if localplayer.is_moving then
                if reference.is_slow_motion() then
                    return 'Slow Walk'
                end

                return 'Moving'
            end

            return 'Standing'
        end

        local function is_disabled()
            return ref.disablers:get(
                get_state()
            )
        end

        local function is_enabled()
            if not ref.checkbox:get() then
                return false
            end

            if not ref.hotkey:get() then
                return false
            end

            return not is_disabled()
        end

        function edge_yaw:update(cmd)
            if not is_enabled() then
                buffer.edge_yaw = false

                return
            end

            buffer.edge_yaw = true
        end
    end

    local freestanding = { } do
        local ref = menu_elements.antiaim.features.freestanding

        local last_ack_defensive_side = nil
        local freestanding_side = nil

        local function is_value_near(value, target)
            return math.abs(target - value) <= 2.0
        end

        local function get_target_yaw(player)
            local threat = client.current_threat()

            if threat == nil then
                return nil
            end

            local player_origin = vector(
                entity.get_origin(player)
            )

            local threat_origin = vector(
                entity.get_origin(threat)
            )

            local delta = threat_origin - player_origin
            local _, yaw = delta:angles()

            return yaw - 180
        end

        local function get_approximated_side(yaw)
            if is_value_near(yaw, -90) then
                return -90
            end

            if is_value_near(yaw, 90) then
                return 90
            end

            return nil
        end

        local function get_side()
            local me = entity.get_local_player()

            if me == nil then
                return nil
            end

            local entity_data = c_entity(me)

            if entity_data == nil then
                return nil
            end

            local animstate = entity_data:get_anim_state()

            if animstate == nil then
                return nil
            end

            local target_yaw = get_target_yaw(me)

            if target_yaw == nil then
                return nil
            end

            return get_approximated_side(
                utils.normalize(animstate.eye_angles_y - target_yaw, -180, 180)
            )
        end

        local function get_state()
            if not localplayer.is_onground then
                return 'Air'
            end

            if localplayer.is_crouched then
                return 'Crouching'
            end

            if localplayer.is_moving then
                if reference.is_slow_motion() then
                    return 'Slow Walk'
                end

                return 'Moving'
            end

            return 'Standing'
        end

        local function is_disabled()
            return ref.disablers:get(
                get_state()
            )
        end

        local function is_enabled()
            if not ref.checkbox:get() then
                return false
            end

            if not ref.hotkey:get() then
                return false
            end

            return not is_disabled()
        end

        local function update_freestanding_options(cmd)
            local items = builder:get(
                'Freestanding'
            )

            if items ~= nil and items.override ~= nil and not items.override:get() then
                items = nil
            end

            if freestanding_side ~= nil then
                buffer.pitch = 'Default'

                if items ~= nil then
                    builder:apply_ex(items)
                end
            end
        end

        function freestanding:update(cmd)
            if not is_enabled() then
                freestanding_side = nil
                return
            end

            if cmd.chokedcommands == 0 then
                freestanding_side = get_side()
            end

            buffer.freestanding = true
            update_freestanding_options(cmd)
        end
    end

    local manual_yaw = { } do
        local ref = menu_elements.antiaim.features.manual_yaw

        local current_dir = nil
        local hotkey_data = { }

        local dir_rotations = {
            ['left'] = -90,
            ['right'] = 90,
            ['forward'] = 180
        }

        local function handle_hotkey(item, dir)
            -- item:set 'On hotkey'

            local state = item:get()

            if hotkey_data[item.ref] == nil then
                hotkey_data[item.ref] = {
                    state = state,
                    last_time = 0
                }
            end

            local data = hotkey_data[item.ref]

            if ref.options:get 'Spam manuals' and dir ~= nil then
                local tick = globals.tickcount()

                if state and data.last_time < (tick - 11) then
                    if current_dir ~= dir then
                        current_dir = dir
                    else
                        current_dir = nil
                    end

                    data.last_time = tick
                end
            else
                if state and not data.state then
                    if current_dir ~= dir then
                        current_dir = dir
                    else
                        current_dir = nil
                    end
                end
            end

            data.state = state
        end

        local function on_paint_ui()
            handle_hotkey(ref.left, 'left')
            handle_hotkey(ref.right, 'right')
            handle_hotkey(ref.forward, 'forward')

            handle_hotkey(ref.reset, nil)
        end

        function manual_yaw:get()
            return current_dir
        end

        function manual_yaw:update(cmd, team)
            local angle = dir_rotations[
                current_dir
            ]

            if angle == nil then
                return false
            end

            buffer.enabled = true

            buffer.edge_yaw = false
            buffer.freestanding = false

            buffer.roll = 0

            buffer.defensive = nil

            if ref.options:get 'Disable yaw modifiers' then
                buffer.yaw_offset = 0

                buffer.yaw_left = 0
                buffer.yaw_right = 0

                buffer.yaw_left_delay = nil
                buffer.yaw_right_delay = nil

                buffer.yaw_jitter = 'Off'
                buffer.jitter_offset = 0
            end

            if ref.options:get 'Freestanding body' then
                buffer.yaw_left_delay = nil
                buffer.yaw_right_delay = nil

                buffer.body_yaw = 'Static'
                buffer.body_yaw_offset = 180
                buffer.freestanding_body_yaw = true
            end

            builder:apply 'Manual AA'

            local yaw = buffer.yaw_offset or 0

            buffer.yaw_base = 'Local view'
            buffer.yaw_offset = yaw + angle

            return true
        end

        local callbacks do
            local function on_enabled(item)
                local value = item:get()

                if not value then
                    current_dir = nil
                end

                utils.event_callback('paint_ui', on_paint_ui, value)
            end

            ref.checkbox:set_callback(
                on_enabled, true
            )
        end
    end

    local avoid_backstab = { } do
        local ref = menu_elements.antiaim.features.avoid_backstab

        local function is_weapon_knife(weapon)
            local weapon_info = csgo_weapons(weapon)

            if weapon_info == nil then
                return false
            end

            -- is weapon taser
            if weapon_info.idx == 31 then
                return false
            end

            if weapon_info.type ~= 'knife' then
                return false
            end

            return true
        end

        local function is_player_weapon_knife(player)
            local weapon = entity.get_player_weapon(player)

            if weapon == nil then
                return false
            end

            return is_weapon_knife(weapon)
        end

        local function get_targets(player)
            local targets = { }

            local player_team = entity.get_prop(player, 'm_iTeamNum')
            local player_resource = entity.get_player_resource()

            for i = 1, globals.maxplayers() do
                local is_connected = entity.get_prop(
                    player_resource, 'm_bConnected', i
                )

                if is_connected ~= 1 then
                    goto continue
                end

                local team = entity.get_prop(
                    player_resource, 'm_iTeam', i
                )

                if player == i or player_team == team then
                    goto continue
                end

                local is_alive = entity.get_prop(
                    player_resource, 'm_bAlive', i
                )

                if is_alive then
                    table.insert(targets, i)
                end

                ::continue::
            end

            return targets
        end

        local function get_backstab_angle(player)
            local best_delta = nil
            local best_target = nil
            local best_distancesqr = math.huge

            local origin = vector(
                entity.get_origin(player)
            )

            local me = entity.get_local_player()

            if me == nil then
                return false
            end

            local enemies = get_targets(me)

            for i = 1, #enemies do
                local enemy = enemies[i]

                if not is_player_weapon_knife(enemy) then
                    goto continue
                end

                local enemy_origin = vector(
                    entity.get_origin(enemy)
                )

                local delta = enemy_origin - origin
                local distancesqr = delta:lengthsqr()

                if distancesqr < best_distancesqr then
                    best_distancesqr = distancesqr

                    best_delta = delta
                    best_target = enemy
                end

                ::continue::
            end

            return best_target, best_distancesqr, best_delta
        end

        function avoid_backstab:update()
            if not ref.checkbox:get() then
                return
            end

            local me = entity.get_local_player()

            if me == nil then
                return false
            end

            local target, distancesqr, delta = get_backstab_angle(me)

            local max_distance = ref.distance:get()
            local max_distance_sqr = max_distance * max_distance

            if target == nil or distancesqr > max_distance_sqr then
                return false
            end

            local angle = vector(
                delta:angles()
            )

            buffer.enabled = true
            buffer.yaw_base = 'Local view'

            buffer.yaw = 'Static'
            buffer.yaw_offset = angle.y

            buffer.freestanding_body_yaw = false

            buffer.edge_yaw = false
            buffer.freestanding = false

            buffer.roll = 0

            return true
        end
    end

    local break_lc_triggers = { } do
        local ref = menu_elements.antiaim.features.break_lc_triggers

        local ACT_CSGO_RELOAD = 967

        local GetClientEntity = vtable_bind(
            'client.dll', 'VClientEntityList003',
            3, 'uint32_t(__thiscall*)(void*, int)'
        )

        local m_flFlashDuration = 0x10470 -- dumped nervar
        local m_flFlashBangTime = m_flFlashDuration - 0x10

        local function get_flashbang_time(player)
            if player == nil then
                return nil
            end

            local address = GetClientEntity(player)

            if address == nil then
                return nil
            end

            return ffi.cast('float*', address + m_flFlashBangTime)[0]
        end

        local function get_reload_time(player)
            if player == nil then
                return nil
            end

            local player_info = c_entity(player)

            if player_info == nil then
                return nil
            end

            local anim_layer = player_info:get_anim_overlay(1)

            if anim_layer == nil or anim_layer.entity == nil then
                return nil
            end

            local activity = player_info:get_sequence_activity(
                anim_layer.sequence
            )

            if activity ~= ACT_CSGO_RELOAD then
                return nil
            end

            if anim_layer.weight == 0 then
                return nil
            end

            return anim_layer.cycle
        end

        local function get_flinch(player)
            if player == nil then
                return nil
            end

            local player_info = c_entity(player)

            if player_info == nil then
                return nil
            end

            local anim_layer = player_info:get_anim_overlay(10)

            if anim_layer == nil then
                return nil
            end

            return anim_layer.weight
        end

        local function is_flashed(player)
            local flash_time = get_flashbang_time(player)

            return flash_time ~= nil
                and flash_time > 0
        end

        local function is_reloading(player)
            return get_reload_time(player) ~= nil
        end

        local function is_taking_damage(player)
            local flinch = get_flinch(player)

            return flinch ~= nil
                and flinch ~= 0
        end

        local function should_update()
            if not ref.checkbox:get() then
                return false
            end

            local me = entity.get_local_player()

            if me == nil then
                return false
            end

            if ref.states:get 'Flashed' and is_flashed(me) then
                return true
            end

            if ref.states:get 'Reloading' and is_reloading(me) then
                return true
            end

            if ref.states:get 'Taking damage' and is_taking_damage(me) then
                return true
            end

            return false
        end

        function break_lc_triggers:update(cmd)
            if not should_update() then
                return
            end

            cmd.force_defensive = 1
        end
    end

    local vanish_mode = { } do
        local ref = menu_elements.antiaim.features.vanish

        local function are_enemies_dead()
            local me = entity.get_local_player()

            if me == nil then
                return false
            end

            local my_team = entity.get_prop(me, 'm_iTeamNum')
            local player_resource = entity.get_player_resource()

            for i = 1, globals.maxplayers() do
                local is_connected = entity.get_prop(
                    player_resource, 'm_bConnected', i
                )

                if is_connected ~= 1 then
                    goto continue
                end

                local player_team = entity.get_prop(
                    player_resource, 'm_iTeam', i
                )

                if me == i or player_team == my_team then
                    goto continue
                end

                local is_alive = entity.get_prop(
                    player_resource, 'm_bAlive', i
                )

                if is_alive == 1 then
                    return false
                end

                ::continue::
            end

            return true
        end

        local function should_update()
            local game_rules = entity.get_game_rules()

            if game_rules == nil then
                return false
            end

            local warmup_period = entity.get_prop(
                game_rules, 'm_bWarmupPeriod'
            )

            if ref:get 'On Warmup' and warmup_period == 1 then
                return true
            end

            if ref:get 'No Enemies' and are_enemies_dead() then
                return true
            end

            return false
        end

        function vanish_mode:update()
            if ref:get() == nil then
                return false
            end

            if not should_update() then
                return false
            end

            buffer.enabled = true

            buffer.pitch = 'Custom'
            buffer.pitch_offset = 0

            buffer.yaw = 'Spin'
            buffer.yaw_offset = 100

            buffer.yaw_jitter = 'Off'
            buffer.jitter_offset = 0

            buffer.body_yaw = 'Static'
            buffer.body_yaw_offset = 1

            buffer.freestanding_body_yaw = false

            buffer.defensive = nil

            buffer.edge_yaw = false
            buffer.freestanding = false

            return true
        end
    end

    local function update_antiaim(cmd)
        fakelag_clone:update()

        local active, items = builder:update(cmd)

        break_lc_triggers:update(cmd)

        if manual_yaw:update(cmd) then
            return
        end

        if avoid_backstab:update() then
            return
        end

        if active and items ~= nil and items.defensive ~= nil then
            defensive:apply(cmd, items.defensive)
        end

        edge_yaw:update(cmd)
        freestanding:update(cmd)

        if not safe_head:update(cmd) then
            -- SISKI
        end

        vanish_mode:update()
    end

    local function update_defensive(cmd)
        local list = buffer.defensive

        local is_exploit_active = (
            reference.is_double_tap_active()
            or reference.is_on_shot_antiaim_active()
        )

        if reference.is_duck_peek_assist() then
            is_exploit_active = false
        end

        if not is_exploit_active then
            return false
        end

        local exp_data = exploit.get()
        local defensive = exp_data.defensive

        local is_valid = (
            list ~= nil and
            defensive.left > 0
        )

        if not is_valid then
            return
        end

        buffer:copy(list)
    end

    local function update_buffer(cmd)
        update_defensive(cmd)

        if cmd.chokedcommands == 0 then
            buffer_mods:update_inverter()
            buffer_mods:update_yaw_delay()
        end

        buffer_mods:update_body_yaw()
        buffer_mods:update_yaw_jitter()
        buffer_mods:update_yaw_offset()
    end

    local function on_shutdown()
        fakelag_clone:shutdown()
        buffer:unset()
    end

    local function on_pre_config_save()
        fakelag_clone:shutdown()
        buffer:unset()
    end

    local function on_setup_command(cmd)
        buffer:clear()
        buffer:unset()

        update_antiaim(cmd)
        update_buffer(cmd)

        buffer:set()
    end

    utils.event_callback('shutdown', on_shutdown)
    utils.event_callback('pre_config_save', on_pre_config_save)
    utils.event_callback('setup_command', on_setup_command)
end
