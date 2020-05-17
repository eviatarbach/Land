"""
    get_struct_from_q(any_struct, flow; p_ini)
This function returns the end pressure for rootlayer struct, including rhizosphere conductance.
The p_ini is either the upstream p of the struct or preset value.
Flow in mol s⁻¹, p_end in MPa
"""
function get_struct_p_end_from_q(any_struct::RootLayer, flow::FT; p_ini::FT=FT(Inf)) where {FT}
    if p_ini==Inf
        p_end = any_struct.p_ups
    else
        p_end = p_ini
    end

    #=
    compute the pressure drop along the rhizosphere, note that p_end is corrected for minor change in surface tension
    1. Using van Genuchten equation to compute soil hydraulic conductance Krhiz in the rhizosphere
    2. Calculate dP = flow / Krhiz_i for each of the 10 shells of the rhizosphere
    3. Update the P at the end of the rhizosphere
    =#
    a   = any_struct.soil_a
    m   = any_struct.soil_m
    n   = any_struct.soil_n
    k   = any_struct.k_rhiz
    k_s = get_relative_surface_tension(any_struct.t_soil)
    k_t = get_relative_viscosity(any_struct.t_soil)
    for i in 0:9
        if p_end<0
            shell_t = (NUMB_1 / (NUMB_1 + (a*(-p_end/k_s))^n)) ^ m
        else
            shell_t = NUMB_1
        end
        shell_f  = sqrt(shell_t) * (NUMB_1 - (NUMB_1-shell_t^(NUMB_1/m)) ^ m) ^ NUMB_2
        shell_k  = k * shell_f * log(NUMB_10) / log((NUMB_10-NUMB_0_9*i)/(NUMB_10-NUMB_0_9*(i+1))) / k_t
        dp       = flow / shell_k
        p_end   -= dp
    end

    #=
    1. Compare the P with drought history in the xylem
    2. Using the Weibull function to compute the pressure drop along the xylem: k = k_max * exp( -(-P/b)^c )
    3. Calculate the pressure drop along each slice in the xylem, including the impact from gravity
    4. Update the P at the end of the xylem
    =#
    for i in 1:length(any_struct.p_element)
        p_25   = min(any_struct.p_history[i], p_end / get_relative_surface_tension(any_struct.t_element[i]))
        k_25   = any_struct.k_element[i] * exp( -NUMB_1 * (-p_25/any_struct.b) ^ (any_struct.c) )
        k      = k_25 / get_relative_viscosity(any_struct.t_element[i])
        p_end -= flow / k + ρ_H₂O * gravity * any_struct.z_element[i] * FT(1E-6)
    end

    # return the result
    return p_end
end




"""
    get_struct_from_q(any_struct, flow; p_ini)
This function returns the end pressure for stem struct, including gravity.
The p_ini is either the upstream p of the struct or preset value.
Flow in mol s⁻¹, p_end in MPa
"""
function get_struct_p_end_from_q(any_struct::Stem, flow::FT; p_ini::FT=(Inf)) where {FT}
    if p_ini==Inf
        p_end = any_struct.p_ups
    else
        p_end = p_ini
    end

    #=
    1. Compare the P with drought history in the xylem
    2. Using the Weibull function to compute the pressure drop along the xylem: k = k_max * exp( -(-P/b)^c )
    3. Calculate the pressure drop along each slice in the xylem, including the impact from gravity
    4. Update the P at the end of the xylem
    =#
    for i in 1:length(any_struct.p_element)
        p_25   = min(any_struct.p_history[i], p_end / get_relative_surface_tension(any_struct.t_element[i]))
        k_25   = any_struct.k_element[i] * exp( -NUMB_1 * (-p_25/any_struct.b) ^ (any_struct.c) )
        k      = k_25 / get_relative_viscosity(any_struct.t_element[i])
        p_end -= flow / k + ρ_H₂O * gravity * any_struct.z_element[i] * ΔEP_6
    end

    # return the result
    return p_end
end




"""
    get_struct_from_q(any_struct, flow; p_ini)
This function returns the end pressure for leaf struct, including gravity.
The p_ini is either the upstream p of the struct or preset value.
Flow in mol s⁻¹, p_end in MPa
"""
function get_struct_p_end_from_q(any_struct::Leaf, flow::FT; p_ini::FT=FT(Inf)) where {FT}
    if p_ini==Inf
        p_end = any_struct.p_ups
    else
        p_end = p_ini
    end

    #=
    1. Compare the P with drought history in the xylem
    2. Using the Weibull function to compute the pressure drop along the xylem: k = k_max * exp( -(-P/b)^c )
    3. Calculate the pressure drop along each slice in the xylem, including the impact from gravity
    4. Update the P at the end of the xylem
    =#
    for i in 1:length(any_struct.p_element)
        p_25   = min(any_struct.p_history[i], p_end / get_relative_surface_tension(any_struct.t_element[i]))
        k_25   = any_struct.k_element[i] * exp( -NUMB_1 * (-p_25/any_struct.b) ^ (any_struct.c) )
        k      = k_25 / get_relative_viscosity(any_struct.t_element[i])
        p_end -= flow / k + ρ_H₂O * gravity * any_struct.z_element[i] * ΔEP_6
    end

    # return the result
    return p_end
end
