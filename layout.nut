local WIDTH = 1280;
local HEIGHT = 1024;

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

/**************/
/* FIXED SIZE */
/**************/
fe.layout.width = WIDTH;
fe.layout.height = HEIGHT;
fe.layout.preserve_aspect_ratio = true;

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

        x = 960 - m_cover.width * 0.5 - 20;
        y = 768;
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
                if (val + m_cover.height * 0.5 > 1024 - 16) {
                    val = 1024 - m_cover.height * 0.5 - 16;
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
local box = fe.add_text("", 0, 0, 320, 0);
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

local list = fe.add_listbox(960, 4, 320, 2 * 768);
list.charsize = 24;
list.bg_alpha = 128;
list.sel_alpha = 224;
list.set_sel_rgb(0, 0, 0);
list.set_bg_rgb(0, 0, 0);
list.set_selbg_rgb(209, 72, 65);
list.align = Align.Left;
list.font = "BebasNeue";
list.rows = 25;
list.format_string = "[!format]";

local list_border = fe.add_text("", 959, 0, 1, 1024);
list_border.set_bg_rgb(1, 1, 1);

fe.add_image("controls.png", 474, 952).alpha = 224;

/*****************/
/* SYSTEM CORNER */
/*****************/
class CornerStripe {
    m_surface = null;
    m_border = null;
    m_background = null;
    m_logo = null;

    constructor() {
        m_surface = fe.add_surface(1920, 1280);

        m_border = m_surface.add_text("", 0, 0, 1920, 1280);
        m_border.set_bg_rgb(1, 1, 1);

        m_background = m_surface.add_text("", 0, 1, 1920, 1280);
        m_background.set_bg_rgb(209, 72, 65);

        m_logo = fe.add_image("systems/[DisplayName].png", 960, 64, 192, 96);
        m_logo.preserve_aspect_ratio = true;

        m_surface.origin_x = 960;
        m_surface.origin_y = 640;

        m_logo.origin_x = 96;
        m_logo.origin_y = 48;

        x = 128;
        y = 128;
        rotation = -45;
        height = 128;
    }

    function _set(idx, val) {
        switch (idx) {
            case "x":
                m_surface.x = val;
                m_logo.x = val;
                break;
            case "y":
                m_surface.y = val;
                m_logo.y = val;
                break;
            case "height":
                m_border.height = val + 2;
                m_background.height = val;

                m_border.y = m_surface.origin_y - m_border.height * 0.5;
                m_background.y = m_surface.origin_y - m_background.height * 0.5;

                local lheight = 128 + ((val.tofloat() - 128) / 1152) * 112;

                m_logo.width = lheight * 1.5;
                m_logo.height = lheight * 0.75;
                
                m_logo.origin_x = m_logo.width * 0.5;
                m_logo.origin_y = m_logo.height * 0.5;

                break;
            case "rotation":
                m_surface.rotation = val;
                m_logo.rotation = val;
                break;
            case "bg_red":
                m_background.bg_red = val;
                break;
            case "bg_green":
                m_background.bg_green = val;
                break;
            case "bg_blue":
                m_background.bg_blue = val;
                break;
            case "index":
                local system = "default";

                if (fe.displays[val].name in systems)
                    system = fe.displays[val].name;

                bg_red = systems[system][0];
                bg_green = systems[system][1];
                bg_blue = systems[system][2];

                m_logo.file_name = "systems/" + system + ".png";
                break;
        }
    }
}

local corner = CornerStripe();

function on_transition(ttype, var, ttime) {
    switch (ttype) {
        case Transition.ToNewList:
            corner.index = fe.list.display_index;

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
    }
}
fe.add_transition_callback("on_transition");
