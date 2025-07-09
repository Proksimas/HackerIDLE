shader_type canvas_item;

// Centre de l’étoile (UV [0,1])
uniform vec2 u_center  = vec2(0.5, 0.5);

// Rayon extérieur maximal de l’étoile (0.0–0.5)
uniform float u_outer_radius : hint_range(0.0, 0.5) = 0.3;

// Nombre de pointes
uniform float u_spikes : hint_range(3, 12) = 5.0;

// Contrôle de la profondeur des pointes (0 = cercle, 1 = pointes très creusées)
uniform float u_sharpness : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    // Coordonnées polaires centrées
    vec2 p = UV - u_center;
    float ang = atan(p.y, p.x);
    float dist = length(p);

    // Modulation radiale : on fait osciller le rayon entre un extérieur et un intérieur
    // grâce au cosinus multiplié par le nombre de pointes.
    float spike_factor = (1.0 + u_sharpness * cos(u_spikes * ang))
                         / (1.0 + u_sharpness);

    float threshold = u_outer_radius * spike_factor;

    // Remplissage
    if (dist < threshold) {
        COLOR = vec4(1.0, 0.843, 0.0, 1.0);
    } else {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);
    }
}
