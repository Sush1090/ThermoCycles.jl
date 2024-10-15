
struct IsenthalpicExpansionValve
    πc
end


function Valve(;name,πc)
    @named inport = CoolantPort()
    @named outport = CoolantPort()
    vars = @variables begin
        P(t)
        s_in(t)
        p_in(t)
        T_in(t)
        h_in(t)
        ρ_in(t)

        s_out(t)
        p_out(t)
        T_out(t)
        h_out(t)
        ρ_out(t)
    end
    para = @parameters begin
        
    end
    eqs = [
        outport.mdot ~ abs(inport.mdot) 
        outport.p ~  inport.p/πc
        outport.h ~ inport.h
        P ~ abs(inport.mdot)*(outport.h - inport.h)
        s_in ~ PropsSI("S","H",inport.h,"P",inport.p,fluid)
        p_in ~ inport.p
        T_in ~ PropsSI("T","H",inport.h,"P",inport.p,fluid)
        h_in ~ inport.h
        ρ_in ~ PropsSI("D","H",inport.h,"P",inport.p,fluid)
        s_out ~ PropsSI("S","H",outport.h,"P",outport.p,fluid)
        p_out ~ outport.p
        T_out ~ PropsSI("T","H",outport.h,"P",outport.p,fluid)
        h_out ~ outport.h
        ρ_out ~ PropsSI("D","H",outport.h,"P",outport.p,fluid)
    ]
    compose(ODESystem(eqs, t, vars, para;name), inport, outport)
end


function Valve(type::IsenthalpicExpansionValve;name)
    @unpack πc = type
    @named inport = CoolantPort()
    @named outport = CoolantPort()
    vars = @variables begin
        P(t)
        s_in(t)
        p_in(t)
        T_in(t)
        h_in(t)
        ρ_in(t)

        s_out(t)
        p_out(t)
        T_out(t)
        h_out(t)
        ρ_out(t)
    end
    para = @parameters begin
        
    end
    eqs = [
        outport.mdot ~ abs(inport.mdot) 
        outport.p ~  inport.p/πc
        outport.h ~ inport.h
        P ~ abs(inport.mdot)*(outport.h - inport.h)
        s_in ~ PropsSI("S","H",inport.h,"P",inport.p,fluid)
        p_in ~ inport.p
        T_in ~ PropsSI("T","H",inport.h,"P",inport.p,fluid)
        h_in ~ inport.h
        ρ_in ~ PropsSI("D","H",inport.h,"P",inport.p,fluid)
        s_out ~ PropsSI("S","H",outport.h,"P",outport.p,fluid)
        p_out ~ outport.p
        T_out ~ PropsSI("T","H",outport.h,"P",outport.p,fluid)
        h_out ~ outport.h
        ρ_out ~ PropsSI("D","H",outport.h,"P",outport.p,fluid)
    ]
    compose(ODESystem(eqs, t, vars, para;name), inport, outport)
end

export IsenthalpicExpansionValve, Valve