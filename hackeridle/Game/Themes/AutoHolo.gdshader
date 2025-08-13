shader_type canvas_item;
render_mode unshaded; // (voir note "Blend add" plus bas)

// --- Texture source
uniform sampler2D src_tex : source_color;

// --- Auto-couleur depuis la texture
uniform bool  auto_outline_from_texture = true;
uniform float sample_inset_px = 2.0;  // profondeur à l'intérieur pour l'échantillon
uniform float color_gain      = 1.0;  // petit boost de teinte (1=neutre)

// --- Fallbacks si auto désactivé
uniform vec4 outline_color_fallback : source_color = vec4(0.82, 0.28, 1.0, 1.0);
uniform vec4 glow_color_fallback    : source_color = vec4(1.00, 0.36, 0.95, 1.0);

// --- Tailles (px)
uniform float outline_size = 8.0;
uniform float glow_size    = 40.0;
uniform int   glow_rings   = 10;
uniform float glow_falloff = 2.8;

// --- Opacités
uniform float outline_opacity = 1.0;
uniform float glow_opacity    = 0.6;

// --- Détection alpha / douceur bord
uniform float alpha_threshold = 0.1;
uniform float feather = 1.0;

const int DIRS = 16;
float atex(vec2 uv){ return texture(src_tex, uv).a; }

float dilate(vec2 uv, float radius_px, vec2 tex_sz){
    vec2 step_uv = radius_px / tex_sz;
    float occ = 0.0;
    for (int i=0; i<DIRS; i++){
        float ang = 6.2831853 * float(i) / float(DIRS);
        vec2 dir = vec2(cos(ang), sin(ang));
        occ = max(occ, atex(uv + dir * step_uv));
    }
    return occ;
}

// gradient alpha (pour trouver la normale du bord)
vec2 alpha_grad(vec2 uv, vec2 px){
    float axp = atex(uv + vec2(px.x, 0.0));
    float axm = atex(uv - vec2(px.x, 0.0));
    float ayp = atex(uv + vec2(0.0, px.y));
    float aym = atex(uv - vec2(0.0, px.y));
    return vec2(axp - axm, ayp - aym);
}

// moyenne couleur interne pondérée par alpha (pas de “blanc/gris”)
vec3 sample_inner_color(vec2 uv, vec2 tex_sz, float inset_px){
    vec2 px = 1.0 / tex_sz;

    // direction vers l’intérieur
    vec2 g = alpha_grad(uv, px);
    vec2 inward = (dot(g,g) < 1e-6) ? normalize(vec2(0.5) - uv) : normalize(-g);
    vec2 perp = vec2(-inward.y, inward.x);

    // 9 taps à l’intérieur (disque petit)
    float d = max(1.0, inset_px) / tex_sz.x; // en UV (approx isotrope)
    vec2 offsets[9] = vec2[9](
        -inward*d,                      // centre un peu en dedans
        -inward*d + perp*0.6*d,         // anneau
        -inward*d - perp*0.6*d,
        -inward*2.0*d,
        -inward*2.0*d + perp*0.6*d,
        -inward*2.0*d - perp*0.6*d,
        -inward*1.5*d + perp*1.2*d,
        -inward*1.5*d - perp*1.2*d,
        -inward*0.5*d
    );

    vec3 sum_rgb = vec3(0.0);
    float sum_a  = 0.0;
    for (int i=0;i<9;i++){
        vec2 uv2 = clamp(uv + offsets[i], vec2(0.0), vec2(1.0));
        vec4 c = texture(src_tex, uv2);
        // n’accumule que si bien opaque (évite bord semi-transp.)
        float w = smoothstep(0.75, 0.95, c.a); // seuil souple ~80–95%
        sum_rgb += c.rgb * c.a * w;
        sum_a   += c.a * w;
    }
    vec3 col = (sum_a > 1e-5) ? (sum_rgb / sum_a) : texture(src_tex, uv).rgb;
    return col * color_gain;
}

void fragment(){
    vec4 base = texture(src_tex, UV);
    vec2 tex_sz = vec2(textureSize(src_tex, 0));
    float soft  = feather / max(tex_sz.x, tex_sz.y);

    // masque doux
    float mask = smoothstep(alpha_threshold, alpha_threshold + soft, base.a);

    // outline (extérieur seulement)
    float occ_outline = smoothstep(alpha_threshold, alpha_threshold + soft,
                                   dilate(UV, outline_size, tex_sz));
    float outline_only = clamp(occ_outline - mask, 0.0, 1.0);

    // halo externe (anneaux)
    float glow_accum = 0.0;
    float prev = occ_outline;
    for (int r=1; r<=glow_rings; r++){
        float t = float(r)/float(glow_rings);
        float radius = outline_size + t * glow_size;
        float curr = smoothstep(alpha_threshold, alpha_threshold + soft,
                                dilate(UV, radius, tex_sz));
        float shell = clamp(curr - prev, 0.0, 1.0);
        float w = exp(-glow_falloff * t);
        glow_accum += shell * w;
        prev = curr;
    }
    glow_accum = clamp(glow_accum, 0.0, 1.0);
    float halo_alpha = glow_accum * glow_opacity;

    // couleur néon (depuis texture)
    vec3 auto_col = sample_inner_color(UV, tex_sz, sample_inset_px);
    vec3 outline_col = auto_outline_from_texture ? auto_col : outline_color_fallback.rgb;
    vec3 glow_col    = auto_outline_from_texture ? auto_col : glow_color_fallback.rgb;

    // --- COMPOSITION **ADDITIVE** (look néon) ---
    vec3 rgb = base.rgb;              // base
    rgb += outline_col * outline_only * outline_opacity; // ajout liseré
    rgb += glow_col    * halo_alpha;                      // ajout halo
    rgb = clamp(rgb, 0.0, 1.0);

    // alpha : on garde visible le glow
    float out_a = clamp(mask + outline_only * outline_opacity + halo_alpha, 0.0, 1.0);

    COLOR = vec4(rgb, out_a);
}
