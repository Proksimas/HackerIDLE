shader_type canvas_item;
render_mode unshaded;

// La même texture que ton bouton
uniform sampler2D src_tex : source_color;

// --- Couleurs
uniform vec4 outline_color : source_color = vec4(0.82, 0.28, 1.0, 1.0); // violet
uniform vec4 glow_color    : source_color = vec4(1.00, 0.36, 0.95, 1.0); // halo

// --- Tailles (px)
uniform float outline_size = 8.0;   // épaisseur du liseré
uniform float glow_size    = 40.0;  // largeur totale du halo externe
uniform int   glow_rings   = 10;    // nb d’anneaux pour un dégradé propre
uniform float glow_falloff = 2.8;   // décroissance (plus grand = chute rapide)

// --- Opacités
uniform float outline_opacity = 1.0; // alpha du liseré
uniform float glow_opacity    = 0.6; // alpha max du halo (dégradé jusqu’à 0)

// --- Détection alpha / douceur bord
uniform float alpha_threshold = 0.1;
uniform float feather = 1.0;

const int DIRS = 16;

float atex(vec2 uv) { return texture(src_tex, uv).a; }

float dilate(vec2 uv, float radius_px, vec2 tex_sz) {
    vec2 step_uv = radius_px / tex_sz;
    float occ = 0.0;
    for (int i = 0; i < DIRS; i++) {
        float ang = 6.2831853 * float(i) / float(DIRS);
        vec2 dir = vec2(cos(ang), sin(ang));
        occ = max(occ, atex(uv + dir * step_uv));
    }
    return occ;
}

void fragment() {
    vec4 base = texture(src_tex, UV);

    vec2 tex_sz = vec2(textureSize(src_tex, 0));
    float soft  = feather / max(tex_sz.x, tex_sz.y);

    // Masque du sprite (avec bords adoucis)
    float mask = smoothstep(alpha_threshold, alpha_threshold + soft, base.a);

    // --------- OUTLINE (extérieur seulement) ---------
    float occ_outline = smoothstep(alpha_threshold, alpha_threshold + soft,
                                   dilate(UV, outline_size, tex_sz));
    float outline_only = clamp(occ_outline - mask, 0.0, 1.0);

    // --------- HALO EXTERNE en dégradé de TRANSPARENCE ---------
    float glow_accum = 0.0;
    float prev = occ_outline;
    for (int r = 1; r <= glow_rings; r++) {
        float t = float(r) / float(glow_rings);              // 0→1
        float radius = outline_size + t * glow_size;
        float curr = smoothstep(alpha_threshold, alpha_threshold + soft,
                                dilate(UV, radius, tex_sz));
        float shell = clamp(curr - prev, 0.0, 1.0);          // anneau extérieur
        float w = exp(-glow_falloff * t);                    // poids (déclin)
        glow_accum += shell * w;                             // [0..1]
        prev = curr;
    }
    glow_accum = clamp(glow_accum, 0.0, 1.0);

    // Alpha du halo (dégradé vers 0 en s’éloignant)
    float halo_alpha = glow_accum * glow_opacity;

    // --------- COMPOSITION ---------
    // Couleur du sprite
    vec3 rgb = base.rgb;

    // Teinte du liseré (couleur visible + alpha propre)
    rgb = mix(rgb, outline_color.rgb, outline_only * outline_color.a);

    // Teinte du halo (couleur proportionnelle à son alpha)
    rgb = mix(rgb, glow_color.rgb, halo_alpha);

    // Alpha final = sprite + liseré + halo (dégradé). On clamp à 1.
    float out_a = clamp(mask + outline_only * outline_opacity + halo_alpha, 0.0, 1.0);

    COLOR = vec4(rgb, out_a);
}
