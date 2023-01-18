local WIDTH = fe.layout.width;
local HEIGHT = fe.layout.height;

local systems = {
    "arcade": [211, 84, 0],
    "gameboy": [127, 140, 141],
    "gamegear": [44, 62, 80],
    "gba": [142, 68, 173],
    "gbc": [22, 160, 133],
    "megadrive": [41, 105, 176],
    "neogeo": [52, 73, 94],
    "nes": [209, 72, 65],
    "ngpx": [241, 196, 15],
    "psx": [33, 33, 33],
    "sms": [26, 188, 156],
    "snes": [251, 192, 45],
    "default": [189, 195, 199],
};

/***************/
/* AUDIO FILES */
/***************/
local clics = [
    fe.add_sound("clic.wav", false),
    fe.add_sound("clic.wav", false),
    fe.add_sound("clic.wav", false),
    fe.add_sound("clic.wav", false),
    fe.add_sound("clic.wav", false),
];

local cloc = fe.add_sound("cloc.wav", false);

/*****************/
/* VIDEO PREVIEW */
/*****************/
function get_video(index_offset, filter_offset) {
    local art = fe.get_art("artwork", index_offset, filter_offset, Art.Default);

    if (art.slice(-3) != "mp4")
        art = "snap.png";

    return art;
}

function get_picture(index_offset, filter_offset) {
    local art = fe.get_art("artwork", index_offset, filter_offset, Art.ImagesOnly);

    return art;
}

local snap = fe.add_image("[!get_video]", 0, 0, WIDTH, HEIGHT);
snap.preserve_aspect_ratio = true;
snap.trigger = Transition.EndNavigation;
snap.video_flags = Vid.NoLoop;

/*********/
/* COVER */
/*********/
class Cover {
    m_border = null;
    m_arrow = null;
    m_white = null;
    m_cover = null;

    m_ratio = 1;

    constructor() {
        m_border = fe.add_text("", 0, 0, 0, 0);
        m_border.set_bg_rgb(1, 1, 1);

        m_arrow = fe.add_image("arrow.png");

        m_white = fe.add_text("", 0, 0, 0, 0);
        m_white.set_bg_rgb(255, 255, 255);

        m_cover = fe.add_image("");

        fe.add_transition_callback(this, "on_transition");
    }

    function resize() {
        m_ratio = m_cover.texture_width.tofloat() / m_cover.texture_height;

        width = size()[0];
        height = size()[1];

        x = WIDTH * 0.75 - m_cover.width * 0.5 - 20;
        y = HEIGHT * 0.75;
    }

    function size() {
        if (m_ratio < 1) {
            if (m_ratio < 0.75) {
                return [320 * m_ratio, 320];
            } else {
                return [240, 240 / m_ratio];
            }
        } else {
            if (m_ratio > 1.33) {
                return [320, 320 / m_ratio];
            } else {
                return [240 * m_ratio, 240];
            }
        }
    }

    function _set(idx, val) {
        switch(idx) {
            case "x":
                m_border.x = val - m_border.width * 0.5;
                m_arrow.x = val + m_white.width * 0.5;
                m_white.x = val - m_white.width * 0.5;
                m_cover.x = val;
                break;
            case "y":
                /* Keep on screen */
                if (val + m_cover.height * 0.5 > HEIGHT - 16) {
                    val = HEIGHT - m_cover.height * 0.5 - 16;
                }

                m_border.y = val - m_border.height * 0.5;
                m_arrow.y = val - 12;
                m_white.y = val - m_white.height * 0.5;
                m_cover.y = val;
                break;
            case "width":
                m_border.width = val + 12;
                m_white.width = val + 10;
                m_cover.width = val;

                m_cover.origin_x = m_cover.width * 0.5;
                x = m_cover.x;

                break;
            case "height":
                m_border.height = val + 12;
                m_white.height = val + 10;
                m_cover.height = val;

                m_cover.origin_y = m_cover.height * 0.5;
                y = m_cover.y;

                break;
        }
    }

    function on_transition(ttype, var, ttime) {
        switch (ttype) {
            case Transition.ToNewList:
            case Transition.FromOldSelection:
                m_cover.file_name = get_picture(0, 0);
                resize();
        }
    }
}

local cover = Cover();

/**************/
/* GAMES LIST */
/**************/
local box = fe.add_text("", 0, 0, WIDTH * 0.25, 0);
box.charsize = 24;
box.font = "BebasNeue";
box.alpha = 0;

function format(index_offset, filter_offset) {
    local title = fe.game_info(Info.Title, index_offset, filter_offset);
    
    /* Strip brackets */
    local ex = regexp(@"[\(|\[]");
    local res = ex.capture(title);

    if (res) {
        title = title.slice(0, res[0].begin);
        title = rstrip(title);
    }

    /* Shorten title */
    box.msg = title;
    if (box.msg_wrapped.len() - 1 != box.msg.len()) {
        title = box.msg_wrapped.slice(0, box.msg_wrapped.len() - 3) + "...";
    }

    return title;
}

local list = fe.add_listbox(WIDTH * 0.75, HEIGHT * 0.75 - 930, WIDTH * 0.25, 1800);
list.charsize = 24;
list.bg_alpha = 128;
list.sel_alpha = 224;
list.set_rgb(236, 240, 241);
list.set_sel_rgb(0, 0, 0);
list.set_bg_rgb(0, 0, 0);
list.set_selbg_rgb(209, 72, 65);
list.align = Align.Left;
list.font = "BebasNeue";
list.rows = 30;
list.format_string = "[!format]";

local list_border = fe.add_text("", WIDTH * 0.75 - 1, 0, 1, HEIGHT);
list_border.set_bg_rgb(1, 1, 1);

fe.add_image("controls.png", WIDTH * 0.5 - 166, HEIGHT - 72).alpha = 224;

/*****************/
/* SYSTEM CORNER */
/*****************/
fe.add_image("systems/[DisplayName].png", 0, 0, 384, 384);

/* Random game selection */
local random = {
    "trigger": 0,
    "next_input": 0,
    "next": true,
    "steps": 1,
    "done": 0,
    "dirty": true,
};

function on_transition(ttype, var, ttime) {
    switch (ttype) {
        case Transition.ToNewList:
            list.selbg_red = systems[fe.list.name][0];
            list.selbg_green = systems[fe.list.name][1];
            list.selbg_blue = systems[fe.list.name][2];

            cloc.playing = true;

            break;
        case Transition.FromOldSelection:
            for (local i=0; i<clics.len(); i++) {
                if (!clics[i].playing) {
                    clics[i].playing = true;
                    break;
                }
            }
            break;
        case Transition.FromGame:
            random.dirty = true;

            try {
                snap.video_playing = true;
                snap.video_time = 0;
            } catch (e) {};
            break;
    }
}
fe.add_transition_callback("on_transition");

function tick(ttime) {
    if (random.dirty) {
        /* Regenerate trigger */
        random.trigger = ttime + (snap.video_duration > 5000 ? snap.video_duration : 5000);
        random.steps = rand() % 5 + 5;
        random.done = 0;

        random.dirty = false;
    } else {
        if (ttime > random.trigger) {
            if (random.done < random.steps) {
                if (ttime > random.next_input) {
                    fe.signal("next_game");

                    random.done += 1;
                    random.next_input = ttime + 120;
                }
            } else {
                snap.file_name = get_video(0, 0);
                random.dirty = true;
            }
        }
    }
}
fe.add_ticks_callback("tick");

function on_signal(signal) {
    switch (signal) {
        case "up":
        case "down":
        case "left":
        case "right":
            random.dirty = true;
            break;
        case "custom1":
            try {
                snap.video_playing = false;
            } catch (e) {};

            fe.plugin_command("retroarch", "-L /usr/lib/libretro/libretro_pocketsnes.so -c /usr/share/retroarch/retroarch.cfg /usr/share/attract/roms/tester.sfc");
            random.dirty = true;

            try {
                snap.video_playing = true;
                snap.video_time = 0;
            } catch (e) {};

            break
    }
}
fe.add_signal_handler("on_signal");
