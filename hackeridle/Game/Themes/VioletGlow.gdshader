// Godot 4.3 — Shader 2D (canvas_item)
shader_type canvas_item;
render_mode unshaded;

// Mets la même texture que ton Sprite dans ce champ (dans le ShaderMaterial)
uniform sampler2D src_tex : source_color;

// Couleurs
uniform vec4 outline_color : source_color = vec4(0.84, 0.25, 1.0, 1.0); // violet
uniform vec4 glow_color    : source_color = vec4(1.00, 0.36, 0.95, 1.0); // rose-violet

// Tailles (pixels)
uniform float outline_size   = 8.0;  // épaisseur du liseré
uniform float glow_size      = 40.0; // largeur totale du halo
uniform int   glow_rings     = 10;   // nb d’anneaux pour un dégradé propre
uniform float glow_falloff   = 3.0;  // >2 = chute plus rapide

// Détection d’alpha
uniform float alpha_threshold = 0.1; // seuil d’existence du sprite
uniform float feather         = 1.0; // adoucissement (px)

const int DIRS = 16;

float alpha_at(vec2 uv) { return texture(src_tex, uv).a; }

// Occupation "dilatée" du sprite à une distance (en pixels)
float dilate(float radius_px, vec2 tex_sz, vec2 uv) {
    vec2 step_uv = radius_px / tex_sz;
    float occ = 0.0;
    for (int i = 0; i < DIRS; i++) {
        float ang = 6.2831853 * float(i) / float(DIRS);
        vec2 dir = vec2(cos(ang), sin(ang));
        float a = alpha_at(uv + dir * step_uv);
        occ = max(occ, a);
    }
    return occ;
}

void fragment() {
    vec4 base = texture(src_tex, UV);

    vec2 tex_sz = vec2(textureSize(src_tex, 0));
    float soft  = feather / max(tex_sz.x, tex_sz.y);

    // Masque du sprite (bords lissés)
    float mask = smoothstep(alpha_threshold, alpha_threshold + soft, base.a);

    // ---------- CONTOUR (liseré) ----------
    float occ_outline = smoothstep(alpha_threshold, alpha_threshold + soft,
                                   dilate(outline_size, tex_sz, UV));
    float outline_only = clamp(occ_outline - mask, 0.0, 1.0); // uniquement à l’extérieur

    // ---------- HALO EXTERNE ----------
    // On empile des "anneaux" dilatés en s’éloignant du bord
    float glow = 0.0;
    float prev = occ_outline;
    for (int r = 1; r <= glow_rings; r++) {
        float t = float(r) / float(glow_rings); // 0→1
        float radius = outline_size + t * glow_size;
        float curr = smoothstep(alpha_threshold, alpha_threshold + soft,
                                dilate(radius, tex_sz, UV));
        float shell = clamp(curr - prev, 0.0, 1.0); // anneau uniquement à l’extérieur
        float w = exp(-glow_falloff * t);          // poids (déclin exponentiel)
        glow += shell * w;
        prev = curr;
    }
    glow = clamp(glow, 0.0, 1.0);

    // ---------- COMPOSITION ----------
    vec3 rgb = base.rgb;
    rgb = mix(rgb, outline_color.rgb, outline_only * outline_color.a); // liseré net
    rgb += glow_color.rgb * glow;                                      // halo additif externe

    float out_a = max(mask, outline_only); // le halo n’ajoute pas d’alpha (reste lumière)
    COLOR = vec4(rgb, out_a);
}
