using ModelingToolkit

ModelingToolkit.@independent_variables t
D = Differential(t)
const AtmosphericPressure = 101305 #Pa
const AmbientTemperature = 300 #K

PropsSI(out::AbstractString, name1::AbstractString, value1::Real, name2::AbstractString, value2::Real, fluid::AbstractString) = CoolProp.PropsSI(out, name1, value1, name2, value2, fluid)
@register_symbolic PropsSI(out::AbstractString, name1::AbstractString, value1::Real, name2::AbstractString, value2::Real, fluid::AbstractString)

PhaseSI(name1::AbstractString, value1::Real, name2::AbstractString, value2::Real, fluid::AbstractString) = CoolProp.PhaseSI(name1, value1, name2, value2, fluid)
@register_symbolic PhaseSI(name1::AbstractString, value1::Real, name2::AbstractString, value2::Real, fluid::AbstractString)

global set_fluid = nothing

# macro load_fluid(fluid::AbstractString)
#     setglobal!(CoolPropCycles,:set_fluid,fluid)
#     quote
#         println("The fluid is set to be ", $(esc(variable)))
#     end
# end
# export load_fluid,
export set_fluid

"""
Makes single node at ports. This node is Pressure,Enthalpy and Massflowrate
"""
@connector  function CoolantPort(;name) 
    vars = @variables begin 
        p(t),  [description = "Pressure (Pa)",input = true]
        h(t), [description = "Enthalpy (J/kg)",input = true]
        mdot(t), [description = "Mass Flow Rate (kg/s)",input = true] # alternates sign of variable after every component.
    end
    ODESystem(Equation[], t, vars, [];name=name)
end


"""
This is double node at ports. Inport and outport. 
"""
function CoolComponent(;name) 
    @named inport = CoolantPort()
    @named outport = CoolantPort()
    vars = @variables begin
        Δp(t) 
        Δmdot(t) 
        Δh(t) 
    end
    eqs = [
        Δp ~ outport.p - inport.p
        Δh ~ outport.h - inport.h
        Δmdot ~ outport.mdot - inport.mdot
    ]
    compose(ODESystem(eqs, t, vars, [];name=name), inport, outport)
end


"""
Mass source -  Use when the cycle needs a start point. Requires initial enthalpy,pressure and Massflowrate
"""
function MassSource(;name,source_pressure = 101305,source_enthalpy=1e6,source_mdot=5,fluid::AbstractString = set_fluid) 
    if isnothing(fluid)
        throw(error("Fluid not selected"))
    end
    @named port = CoolantPort()
    para = @parameters begin

    end
    vars = @variables begin
        mdot(t)
        s(t)
        p(t)
        T(t)
        h(t)
        ρ(t)
     end

    eqs = [
        port.mdot ~ source_mdot # Outflow is negative
        port.p ~ source_pressure
        port.h ~ source_enthalpy
        mdot ~ port.mdot
        s ~ PropsSI("S","H",port.h,"P",port.p,fluid)
        p ~ port.p
        T ~ PropsSI("T","H",port.h,"P",port.p,fluid)
        h ~ port.h
        ρ ~ PropsSI("D","H",port.h,"P",port.p,fluid)
    ]
    compose(ODESystem(eqs, t, vars, para;name),port)
end

"""
Mass sink -  Use when the cycle needs a end point. Sets the final port input values to the variables
"""
function MassSink(;name,fluid::AbstractString = set_fluid) 
    if isnothing(fluid)
        throw(error("Fluid not selected"))
    end
    @named    port = CoolantPort()
    para = @parameters begin
        
    end
    vars = @variables begin
        mdot(t)
        s(t)
        p(t)
        T(t)
        h(t)
        ρ(t)
     end

   eqs = [
    port.p ~ p
    port.h ~ h
    mdot ~ port.mdot
    s ~ PropsSI("S","H",port.h,"P",port.p,fluid)
    p ~ port.p
    T ~ PropsSI("T","H",port.h,"P",port.p,fluid)
    h ~ port.h
    ρ ~ PropsSI("D","H",port.h,"P",port.p,fluid)
   ]
   compose(ODESystem(eqs, t, vars, para;name),port)
end


"""
ComputeSpecificLatentHeat: Computes the specific latent heat of the give fluid at a particular varliable value. var1 should not be enthalpy or vapour quality
*Arguments:
-'var1'     : Variable String. Uses CoolProp variable strings
-'value1'   : Value of the variale chosen
-'fluid'    : Fluid name string
"""
function ComputeSpecificLatentHeat(var1::AbstractString,value1,fluid::AbstractString)
    @assert var1 != "Q"
    H_L = PropsSI("H",var1,value1,"Q",0,fluid)
    H_V = PropsSI("H",var1,value1,"Q",1,fluid)
    return H_V - H_L
end
@register_symbolic ComputeSpecificLatentHeat(var1::AbstractString,value1,fluid::AbstractString)

export CoolantPort,CoolComponent,MassSource,MassSink,AmbientTemperature,AtmosphericPressure,ComputeSpecificLatentHeat




# function ForceState_ph(;name,p_,h_,fluid)
#     @named port = CoolantPort()
#     vars = @variables begin
#         mdot(t)
#         s(t)
#         p(t)
#         T(t)
#         h(t)
#         ρ(t)
#     end
#     eqs = [
#         mdot ~ abs(port.mdot)
#         p ~ p_
#         h ~ h_
#         port.h ~ h
#         port.p ~ p
#         s ~ PropsSI("S","P",p,"H",h,fluid)
#         T ~ PropsSI("T","P",p,"H",h,fluid)
#         ρ ~ PropsSI("D","P",p,"H",h,fluid)
#     ]
#     compose(ODESystem(eqs, t, vars, [];name=name), inport, outport)
# end

# function ForceState(;name,p=nothing,h=nothing,T=nothing,s=nothing,ρ=nothing,fluid::AbstractString)
    # if !isnothing(p) && h !isnothing(h)
    #     return ForceState_ph(p_=p,h_=h,fluid=fluid)
    # end
# end