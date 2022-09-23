/* Fixed size */
fe.layout.width = 1280;
fe.layout.height = 1024;
fe.layout.preserve_aspect_ratio = true;

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

class Outline {
    m_layers = null;

    constructor(surface, x = 0, y = 0, width = 0, height = 0, shadow = true) {
        m_layers = [];

        if (shadow) {
            //for (local i=0; i<5; i++) {
            //    m_layers.push(surface.add_text("", 0, 0, 0, 0));
            //    m_layers[i].set_bg_rgb(1, 1, 1);
            //    m_layers[i].bg_alpha = 32;
            //}
        }

        local border = surface.add_text("", 0, 0, 0, 0);
        border.set_bg_rgb(1, 1, 1);
        
        m_layers.push(border);

        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
    }

    function _set(idx, val) {
        switch (idx) {
            case "x":
                for (local i = 0; i < m_layers.len(); i++)
                    m_layers[i].x = val - (m_layers.len() - i);
                break;
            case "y":
                for (local i = 0; i < m_layers.len(); i++)
                    m_layers[i].y = val - (m_layers.len() - i);
                break;
            case "width":
                for (local i = 0; i < m_layers.len(); i++)
                    m_layers[i].width = val + 2 * (m_layers.len() - i);
                break;
            case "height":
                for (local i = 0; i < m_layers.len(); i++)
                    m_layers[i].height = val + 2 * (m_layers.len() - i);
                break;
        }
    }
}

/*****************/
/* VIDEO PREVIEW */
/*****************/
local snap = fe.add_artwork("snap", 0, 0, 1280, 1024);
snap.preserve_aspect_ratio = true;
snap.trigger = Transition.EndNavigation;

/************/
/* Conveyor */
/************/
class ConveyorBelt {
    m_color = null;
    m_title = null;
    m_letter = null;

    constructor() {
        /* Top and bottom border */
        fe.add_text("", 0, 639, 1280, 1).set_bg_rgb(1, 1, 1);
        fe.add_text("", 0, 992, 1280, 1).set_bg_rgb(1, 1, 1);

        /* Background */
        local background = fe.add_text("", 0, 640, 1280, 352);
        background.set_bg_rgb(1, 1, 1);
        background.bg_alpha = 128;

        /* Colored stripe */
        Outline(fe, 0, 704, 1280, 224);
        m_color = fe.add_text("", 0, 704, 1280, 224);

        /* Game title */
        m_title = fe.add_text("", 0, 648, 1280, 48);
        m_title.set_rgb(255, 255, 255);
        m_title.font = "BebasNeue";
        m_title.align = Align.MiddleLeft;
        m_title.margin = 0;

        /* First letter */
        m_letter = fe.add_text("", 0, 648, 1280, 48);
        m_letter.set_rgb(255, 255, 255);
        m_letter.font = "BebasNeue";
        m_letter.align = Align.MiddleCentre;

        /* Controls information */
        local text, image;
        image = fe.add_image("controls/left_right.png", 768, 936, 48, 48);
        image.preserve_aspect_ratio = true;

        text = fe.add_text("GAMES", 832, 944, 64, 32);
        text.set_rgb(255, 255, 255);
        text.font = "BebasNeue";
        text.align = Align.MiddleLeft;
        text.margin = 0;

        local text, image;
        image = fe.add_image("controls/up_down.png", 928, 936, 48, 48);
        image.preserve_aspect_ratio = true;

        text = fe.add_text("SYSTEMS", 992, 944, 96, 32);
        text.set_rgb(255, 255, 255);
        text.font = "BebasNeue";
        text.align = Align.MiddleLeft;
        text.margin = 0;

        local text, image;
        image = fe.add_image("controls/a.png", 1096, 936, 48, 48);
        image.preserve_aspect_ratio = true;

        text = fe.add_text("PLAY", 1152, 944, 64, 32);
        text.set_rgb(255, 255, 255);
        text.font = "BebasNeue";
        text.align = Align.MiddleLeft;
        text.margin = 0;
    }

    function set_index(index) {
        local system = "default";

        if (fe.displays[index].name in systems)
            system = fe.displays[index].name;

        m_color.set_bg_rgb(
            systems[system][0],
            systems[system][1],
            systems[system][2]
        );
    }

    function show_letter(show = true) {
        if (show) {
            m_letter.alpha = 255;
            m_letter.msg = "[ " + fe.game_info(Info.Title).slice(0, 1) + " ]";
        } else {
            m_letter.alpha = 0;
        }
    }

    function show_title(show = true, x = 0) {
        if (show) {
            m_title.alpha = 255;
            m_title.x = x;
            m_title.width = 1280 - x - 16;

            m_title.msg = strip_brackets(fe.game_info(Info.Title));

            if (m_title.msg_wrapped.len() - 1 != m_title.msg.len()) {
                m_title.msg = m_title.msg_wrapped.slice(0, m_title.msg_wrapped.len() - 3) + "...";
            }
        } else {
            m_title.alpha = 0;
        }
    }

    function strip_brackets(str) {
        local stripped = str;
        local ex = regexp(@"[\(|\[]");
        local res = ex.capture(stripped);

        if (res) {
            stripped = stripped.slice(0, res[0].begin);
            stripped = rstrip(stripped);
        }

        return stripped;
    }
} 

class MainThumb {
    m_art = null;
    m_outline = null;

    constructor() {
        m_outline = Outline(fe);
        m_art = fe.add_artwork("flyer");
    }

    function grow(progress) {
        local target = grown_size();

        width = 192 + (target[0] - 192) * progress;
        height = 192 + (target[1] - 192) * progress;
    }

    function update_ratio() {
        if (m_art.texture_height == 0 ||
            m_art.height == 0)
            return;

        local art_ratio = m_art.texture_width.tofloat() / m_art.texture_height;
        local current_ratio = m_art.width.tofloat() / m_art.height;

        if (art_ratio < 1) {
            m_art.subimg_height = m_art.texture_width / current_ratio;
        } else {
            m_art.subimg_width = m_art.texture_height * current_ratio;
        }
    }

    function grown_size() {
        if (m_art.texture_height == 0)
            return [360, 360];

        local ratio = m_art.texture_width.tofloat() / m_art.texture_height;

        if (ratio < 1) {
            if (ratio < 0.75) {
                return [480 * ratio, 480];
            }

            return [360, 360 / ratio];
        } else {
            if (ratio > 1.33) {
                return [480, 480 / ratio];
            }

            return [360 * ratio , 360];
        }
    }   

    function _set(idx, val) {
        switch (idx) {
            case "x":
                m_art.x = val - m_art.width * 0.5 - 9;
                m_outline.x = val - m_art.width * 0.5 - 9;
                break;
            case "y":
                m_art.y = val - m_art.height * 0.5;
                m_outline.y = val - m_art.height * 0.5;

                /* Keep on screen */
                if (m_art.y + m_art.height > 1024 - 16) {
                    m_art.y = 1024 - m_art.height - 16;
                    m_outline.y = 1024 - m_art.height - 16;
                }
                break;
            case "width":
                m_art.width = val;
                m_outline.width = val;
                update_ratio();
                break;
            case "height":
                m_art.height = val;
                m_outline.height = val;
                update_ratio();
                break;
        }
    }
}

class ConveyorThumb {
    m_surface = null;
    m_art = null;

    constructor() {
        m_surface = fe.add_surface(204, 204);
        Outline(m_surface, 6, 6, 192, 192);
        m_art = m_surface.add_artwork("flyer", 6, 6, 192, 192);

        m_surface.y = 714;

        fe.add_transition_callback(this, "on_transition");
    }

    function update_ratio() {
        if (m_art.texture_width < m_art.texture_height) {
            m_art.subimg_height = m_art.texture_width;
        } else {
            m_art.subimg_width = m_art.texture_height;
        }
    }

    function swap(thumb) {
        m_art.swap(thumb.m_art);
        update_ratio();
    }

    function _set(idx, val) {
        switch (idx) {
            case "index_offset":
                m_art.index_offset = val;
                break;
            case "x":
                m_surface.x = val;
                break;
            case "alpha":
                m_surface.alpha = val;
                break;
        }
    }

    function on_transition(ttype, var, ttime) {
        switch (ttype) {
            case Transition.ToNewList:
            case Transition.FromOldSelection:
                update_ratio();
                break;
        }
    }
}

class Conveyor {
    m_belt = null;
    m_thumbs = null;
    m_transition_ms = 150;
    m_center_x = 0;
    m_main_index = 0;
    m_main_thumb = null;
    m_main_state = "grown";

    constructor(main_index, center_x) {
        m_belt = ConveyorBelt();

        m_thumbs = [];
        for (local i = 0; i < 8; i++) {
            m_thumbs.push(ConveyorThumb());
            m_thumbs[i].index_offset = i - main_index;
            m_thumbs[i].x = i * 224;

            if (i == main_index)
                m_thumbs[i].alpha = 0;
        }

        m_main_thumb = MainThumb();

        m_main_index = main_index;
        m_center_x = center_x;

        fe.add_transition_callback(this, "on_transition");
    }

    function slide(progress, grow = true) {
        if (grow) {
            if (m_main_state == "grown") {
                if (progress > 0)
                    m_main_thumb.grow(1 - progress);
                else
                    m_main_thumb.grow(1 + progress);
            } else {
                m_main_thumb.grow(0);
            }
        }

        m_main_thumb.x = m_center_x + 224 * progress;
        m_main_thumb.y = 816;

        for (local i = 0; i < m_thumbs.len(); i++) {
            local pos = (i - m_main_index) * 224;
            pos += progress * 224;
            pos += m_center_x - 112;

            if (i < m_main_index) {
                pos = pos + 112 - m_main_thumb.m_art.width * 0.5 - 12;
            } else if (i > m_main_index) {
                pos = pos - 112 + m_main_thumb.m_art.width * 0.5 + 12;
            }

            m_thumbs[i].x = pos;
        }

        return true;
    }

    function swap(var) {
        if (var < 0) {
            for (local i = m_thumbs.len() - 1; i > 0; i--)
                m_thumbs[i].swap(m_thumbs[i - 1]);
        } else {
            for (local i = 0; i < m_thumbs.len() - 1; i++)
                m_thumbs[i].swap(m_thumbs[i + 1]);
        }
    }

    function on_transition(ttype, var, ttime) {
        switch (ttype) {
            case Transition.ToNewList:
                slide(0);
                m_belt.show_title(true, m_main_thumb.m_art.x + m_main_thumb.m_art.width + 28);
                m_belt.set_index(fe.list.display_index);
                break;
            case Transition.EndNavigation:
                m_belt.show_letter(false);

                local progress = ttime.tofloat() / m_transition_ms;
                if (progress < 1) {
                    m_main_thumb.grow(progress);
                    m_main_thumb.x = m_center_x;
                    m_main_thumb.y = 816;
                    slide(0, false);
                    return true;
                }

                m_main_state = "grown";
                m_main_thumb.grow(1);
                slide(0, false);
                m_main_thumb.x = m_center_x;
                m_main_thumb.y = 816;

                m_belt.show_title(true, m_main_thumb.m_art.x + m_main_thumb.m_art.width + 28);

                break;
            case Transition.ToNewSelection:
                m_belt.show_title(false);

                local progress = - var * ttime.tofloat() / m_transition_ms;

                if (abs(progress) < 1) {
                    slide(progress);
                    return true;
                }

                slide(-var);
                swap(var);

                break;
            case Transition.FromOldSelection:
                m_main_state = "shrinked";
                slide(0);
                m_belt.show_letter(true);
                break;
        }
    }
}

/***************/
/* SYSTEM LOGO */
/***************/
class CornerStripe {
    m_index = null;
    m_surface = null;
    m_color = null;
    m_logo = null;

    constructor(index, shadow = false) {
        m_surface = fe.add_surface(1920, 172);

        Outline(m_surface, 6, 6, 1920, 160, shadow);

        m_color = m_surface.add_text("", 6, 6, 1920, 160);

        m_logo = m_surface.add_image("", 832, 22, 256, 128);
        m_logo.preserve_aspect_ratio = true;

        m_surface.origin_x = 960;
        m_surface.origin_y = 86;

        set_index(index);
    }

    function set_index(index) {
        local system = "default";

        if (fe.displays[index].name in systems)
            system = fe.displays[index].name;

        m_color.set_bg_rgb(
            systems[system][0],
            systems[system][1],
            systems[system][2]
        );

        m_logo.file_name = "systems/" + system + ".png";
    }

    function _set(idx, val) {
        switch (idx) {
            case "x":
                m_surface.x = val;
                break;
            case "y":
                m_surface.y = val;
                break;
            case "rotation":
                m_surface.rotation = val;
                break;
            case "index":
                set_index(val);
                break;
            case "alpha":
                m_surface.alpha = val;
                break;
        }
    }
}

class Corner {
    m_fade = null;
    m_stripes = null;
    m_masks = null;

    m_state = "corner";
    m_reset_timer = true;
    m_revert_timer = false;
    m_timer = 0;
    m_transition_ms = 300;

    m_action = null;

    constructor() {
        m_fade = fe.add_text("", 0, 0, 1280, 1024);
        m_fade.set_bg_rgb(1, 1, 1);

        m_stripes = [
            CornerStripe(0, true),
            CornerStripe(0),
            CornerStripe(0),
        ];

        m_masks = [
            fe.add_text("", 0, 0, 1280, 432),
            fe.add_text("", 0, 592, 1280, 432),
        ];
        m_masks[0].set_bg_rgb(1, 1, 1);
        m_masks[1].set_bg_rgb(1, 1, 1);

        fe.add_ticks_callback(this, "on_tick");
        fe.add_signal_handler(this, "on_signal");
        fe.add_transition_callback(this, "on_transition");
    }

    function grow(progress) {
        m_stripes[0].x = 1152 - 512 * progress;
        m_stripes[0].y = 128 + 384 * progress;
        m_stripes[0].rotation = 45 * (1 - progress);

        m_fade.bg_alpha = 255 * progress;
    }

    function slide(progress) {
        if (progress == 0) {
            m_masks[0].bg_alpha = 0;
            m_masks[1].bg_alpha = 0;

            m_stripes[1].alpha = 0;
            m_stripes[2].alpha = 0;
        } else {
            m_masks[0].bg_alpha = 255;
            m_masks[1].bg_alpha = 255;

            m_stripes[1].alpha = 255;
            m_stripes[2].alpha = 255;
        }

        m_stripes[0].x = 640;
        m_stripes[1].x = 640;
        m_stripes[2].x = 640;

        m_stripes[0].y = 512 + 160 * progress;
        m_stripes[1].y = 352 + 160 * progress;
        m_stripes[2].y = 672 + 160 * progress;
    }

    function switch_state(state, revert = false) {
        m_state = state;

        if (revert) {
            m_revert_timer = true;
        } else {
            m_reset_timer = true;
        }
    }

    function on_tick(time) {
        if (m_reset_timer) {
            m_timer = time;
            m_reset_timer = false;
        } else if (m_revert_timer) {
            m_timer = time - m_transition_ms + (time - m_timer);
            m_revert_timer = false;
        }

        local progress = (time.tofloat() - m_timer) / m_transition_ms;

        switch (m_state) {
            case "growing":
                if (progress < 1) {
                    grow(progress);
                } else {
                    grow(1);
                    switch_state("sliding");
                }
                break;
            case "shrinking":
                if (progress < 1) {
                    grow(1 - progress);
                } else {
                    grow(0);
                    switch_state("corner");
                }
                break;
            case "sliding":
                if (progress < 1) {
                    if (m_action == "prev_display")
                        slide(progress);

                    if (m_action == "next_display")
                        slide(-progress);
                } else {
                    if (m_action == "prev_display")
                        slide(1);

                    if (m_action == "next_display")
                        slide(-1);

                    switch_state("switching");
                }
                break;
            case "grown":
                slide(0);
                grow(1);

                if (progress > 1) {
                    switch_state("shrinking");
                }
                break;
            case "switching":
                fe.signal(m_action);
                m_action = null;
                break;
        }
    }

    function on_signal(signal) {
        switch (signal) {
            case "next_display":
            case "prev_display":
                switch (m_state) {
                    case "growing":
                    case "sliding":
                        return true;
                    case "shrinking":
                        m_action = signal;
                        switch_state("growing", true);
                        return true;
                    case "corner":
                        m_action = signal;
                        switch_state("growing");
                        return true;
                    case "grown":
                        m_action = signal;
                        switch_state("sliding");
                        return true;
                    case "switching":
                        return false;
                }
                break;
        }
    }

    function on_transition(ttype, var, ttime) {
        switch (ttype) {
            case Transition.ToNewList:
                local previous = fe.list.display_index, next = fe.list.display_index;

                do {
                    previous = ((previous - 1) + fe.displays.len()) % fe.displays.len();
                } while (!fe.displays[previous].in_cycle);

                do {
                    next = (next + 1) % fe.displays.len();
                } while (!fe.displays[next].in_cycle);

                m_stripes[0].index = fe.list.display_index;
                m_stripes[1].index = previous;
                m_stripes[2].index = next;
                switch_state("grown");
                break;
        }
    }
}

local conveyor = Conveyor(2, 320);
local corner = Corner();

/* Masks */
fe.add_text("", -320, 0, 320, 1024).set_bg_rgb(1, 1, 1);
fe.add_text("", 1280, 0, 320, 1024).set_bg_rgb(1, 1, 1);
