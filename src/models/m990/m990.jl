# The given fields define the entire model structure.
# We can then concisely pass around a Model object to the remaining steps of the model
#   (solve, estimate, and forecast).
type Model990{T} <: AbstractDSGEModel{T}
    parameters::ParameterVector{T}                  # vector of all of the model parameters
    steady_state::ParameterVector{T}                # model steady-state values
    keys::Dict{Symbol,Int}                          # human-readable names for all the model
                                                    # parameters and steady-num_states

    endogenous_states::Dict{Symbol,Int}             # these fields used to create matrices in the
    exogenous_shocks::Dict{Symbol,Int}              # measurement and equilibrium condition equations.
    expected_shocks::Dict{Symbol,Int}               #
    equilibrium_conditions::Dict{Symbol,Int}        #
    endogenous_states_postgensys::Dict{Symbol,Int}  #
    observables::Dict{Symbol,Int}                   #

    spec                                            # The model specification number
    savepath::String                                # The absolute path to the top-level save directory for this
                                                    # model specification

    num_anticipated_shocks::Int                     # Number of anticipated policy shocks
    num_anticipated_shocks_padding::Int             # Padding for nant
    num_anticipated_lags::Int                       # Number of periods back to incorporate zero bound expectations
    num_presample_periods::Int                      # Number of periods in the presample

    reoptimize::Bool                                # Reoptimize the posterior mode
    recalculate_hessian::Bool                       # Recalculate the hessian at the mode
    num_mh_simulations::Int                         #
    num_mh_blocks::Int                              #
    num_mh_burn::Int                                #
    mh_thinning_step::Int                           #

    num_mh_simulations_test::Int                    # These fields are used to test Metropolis-Hastings with
    num_mh_blocks_test::Int                         # a small number of draws from the posterior
    num_mh_burn_test::Int                           #
end

description(m::Model990) = "This is some model that we're trying to make work."

function initialise_model_indices!(m::Model990)
    # Endogenous states
    endogenous_states = [[
        :y_t, :c_t, :i_t, :qk_t, :k_t, :kbar_t, :u_t, :rk_t, :Rktil_t, :n_t, :mc_t,
        :pi_t, :muw_t, :w_t, :L_t, :R_t, :g_t, :b_t, :mu_t, :z_t, :laf_t, :laf_t1,
        :law_t, :law_t1, :rm_t, :sigw_t, :mue_t, :gamm_t, :pist_t, :E_c, :E_qk, :E_i,
        :E_pi, :E_L, :E_rk, :E_w, :E_Rktil, :y_f_t, :c_f_t, :i_f_t, :qk_f_t, :k_f_t,
        :kbar_f_t, :u_f_t, :rk_f_t, :w_f_t, :L_f_t, :r_f_t, :E_c_f, :E_qk_f, :E_i_f,
        :E_L_f, :E_rk_f, :ztil_t, :pi_t1, :pi_t2, :pi_a_t, :R_t1, :zp_t, :E_z];
        [symbol("rm_tl$i") for i = 1:num_anticipated_shocks(m)]]

    # Exogenous shocks
    exogenous_shocks = [[
        :g_sh, :b_sh, :mu_sh, :z_sh, :laf_sh, :law_sh, :rm_sh, :sigw_sh, :mue_sh,
        :gamm_sh, :pist_sh, :lr_sh, :zp_sh, :tfp_sh, :gdpdef_sh, :pce_sh];
        [symbol("rm_shl$i") for i = 1:num_anticipated_shocks(m)]]

    # Expectations shocks
    expected_shocks = [
        :Ec_sh, :Eqk_sh, :Ei_sh, :Epi_sh, :EL_sh, :Erk_sh, :Ew_sh, :ERktil_sh, :Ec_f_sh,
        :Eqk_f_sh, :Ei_f_sh, :EL_f_sh, :Erk_f_sh]

    # Equilibrium conditions
    equilibrium_conditions = [[
        :euler, :inv, :capval, :spread, :nevol, :output, :caputl, :capsrv, :capev,
        :mkupp, :phlps, :caprnt, :msub, :wage, :mp, :res, :eq_g, :eq_b, :eq_mu, :eq_z,
        :eq_laf, :eq_law, :eq_rm, :eq_sigw, :eq_mue, :eq_gamm, :eq_laf1, :eq_law1, :eq_Ec,
        :eq_Eqk, :eq_Ei, :eq_Epi, :eq_EL, :eq_Erk, :eq_Ew, :eq_ERktil, :euler_f, :inv_f,
        :capval_f, :output_f, :caputl_f, :capsrv_f, :capev_f, :mkupp_f, :caprnt_f, :msub_f,
        :res_f, :eq_Ec_f, :eq_Eqk_f, :eq_Ei_f, :eq_EL_f, :eq_Erk_f, :eq_ztil, :eq_pist,
        :pi1, :pi2, :pi_a, :Rt1, :eq_zp, :eq_Ez];
        [symbol("eq_rml$i") for i=1:num_anticipated_shocks(m)]]

    # Additional states added after solving model
    # Lagged states and observables measurement error
    endogenous_states_postgensys = [
        :y_t1, :c_t1, :i_t1, :w_t1, :pi_t1, :L_t1, :Et_pi_t, :lr_t, :tfp_t, :e_gdpdef,
        :e_pce, :u_t1]

    # Measurement equation observables
    observables = [[
        :g_y,         # quarterly output growth
        :hoursg,      # aggregate hours growth
        :g_w,         # real wage growth
        :pi_gdpdef,   # inflation (GDP deflator)
        :pi_pce,      # inflation (core PCE)
        :R_n,         # nominal interest rate
        :g_c,         # consumption growth
        :g_i,         # investment growth
        :sprd,        # spreads
        :pi_long,     # 10-year inflation expectation
        :R_long,      # long-term rate
        :tfp];        # total factor productivity
        [symbol("R_n$i") for i=1:num_anticipated_shocks(m)]] # compounded nominal rates

    for (i,k) in enumerate(endogenous_states);            m.endogenous_states[k]            = i end
    for (i,k) in enumerate(exogenous_shocks);             m.exogenous_shocks[k]             = i end
    for (i,k) in enumerate(expected_shocks);              m.expected_shocks[k]              = i end
    for (i,k) in enumerate(equilibrium_conditions);       m.equilibrium_conditions[k]       = i end
    for (i,k) in enumerate(endogenous_states);            m.endogenous_states[k]            = i end
    for (i,k) in enumerate(endogenous_states_postgensys); m.endogenous_states_postgensys[k] = i+length(endogenous_states) end
    for (i,k) in enumerate(observables);                  m.observables[k]                  = i end
end

function Model990()
    # Model-specific specifications
    spec                            = split(basename(@__FILE__),'.')[1]
    savepath                        = joinpath(dirname(@__FILE__), *("../../../save/",spec))

    # Create the save directories if they don't already exist
    # createSaveDirectories(savepath)

    _num_anticipated_shocks          = 6
    _num_anticipated_shocks_padding  = 20
    _num_anticipated_lags            = 24
    _num_presample_periods           = 2 # TODO: This should be set when the data are read in

    # Estimation specifications
    reoptimize                      = false
    recalculate_hessian             = false
    num_mh_simulations              = 10000
    num_mh_blocks                   = 22
    num_mh_burn                     = 2
    mh_thinning_step                = 5
    num_mh_simulations_test         = 10
    num_mh_blocks_test              = 1
    num_mh_burn_test                = 0

    # initialise empty model
    m = Model990{Float64}(
            # model parameters and steady state values
            @compat(Vector{AbstractParameter{Float64}}()), @compat(Vector{Float64}()), Dict{Symbol,Int}(),

            # model indices
            Dict{Symbol,Int}(), Dict{Symbol,Int}(), Dict{Symbol,Int}(), Dict{Symbol,Int}(), Dict{Symbol,Int}(), Dict{Symbol,Int}(),

            spec,
            savepath,

            _num_anticipated_shocks, _num_anticipated_shocks_padding, _num_anticipated_lags, _num_presample_periods,

            reoptimize,
            recalculate_hessian,
            num_mh_simulations,
            num_mh_blocks,
            num_mh_burn,
            mh_thinning_step,

            num_mh_simulations_test,
            num_mh_blocks_test,
            num_mh_burn_test)

    m <= parameter(:alp,      0.1596, (1e-5, 0.999), (1e-5, 0.999),   SquareRoot(),     Normal(0.30, 0.05),         fixed=false,
                   description="α: Capital elasticity in the intermediate goods sector's Cobb-Douglas production function.",
                   texLabel="\\alpha")

    m <= parameter(:zeta_p,   0.8940, (1e-5, 0.999), (1e-5, 0.999),   SquareRoot(),     BetaAlt(0.5, 0.1),          fixed=false,
                   description="ζ_p: The Calvo parameter. In every period, (1-ζ_p) of the intermediate goods producers optimize prices. ζ_p of them adjust prices according to steady-state inflation, π_star.",
                   texLabel="\\zeta_p")

    m <= parameter(:iota_p,   0.1865, (1e-5, 0.999), (1e-5, 0.999),   SquareRoot(),     BetaAlt(0.5, 0.15),         fixed=false,
                   description="ι_p: The weight on last period's inflation in the equation that describes the intertemporal change in prices for intermediate goods producers who cannot adjust prices. The change in prices is a geometric average of steady-state inflation (π_star, with weight (1-ι_p)) and last period's inflation (π_{t-1})).",
                   texLabel="\\iota_p")

    m <= parameter(:δ,      0.025,                                                                                fixed=true,
                   description="δ: The capital depreciation rate.", texLabel="\\delta" )     # omit from parameter vector

    ## TODO
    m <= parameter(:Upsilon,  1.000,  (0., 10.),     (1e-5, 0.),      Exponential(),    GammaAlt(1., 0.5),          fixed=true,
                   description="Υ: This is the something something.",
                   texLabel="\\mathcal{\\Upsilon}") # is this supposed to be Υ?

    ## TODO - ask Marc and Marco
    m <= parameter(:Φ,   1.1066, (1., 10.),     (1.00, 10.00),   Exponential(),    Normal(1.25, 0.12),         fixed=false,
                   description="Φ: This is the something something.",
                   texLabel="\\Phi")

    ## TODO - figure out how to print primes
    m <= parameter(:S2,       2.7314, (-15., 15.),   (-15., 15.),     Untransformed(),  Normal(4., 1.5),            fixed=false,
                   description="S'': The second derivative of households' cost of adjusting investment.", texLabel="S''")

    m <= parameter(:h,        0.5347, (1e-5, 0.999), (1e-5, 0.999),   SquareRoot(),     BetaAlt(0.7, 0.1),          fixed=false,
                   description="h: Consumption habit persistence.", texLabel="h")

    ## TODO - ask Marc and Marco
    m <= parameter(:ppsi,     0.6862, (1e-5, 0.999), (1e-5, 0.999),   SquareRoot(),     BetaAlt(0.5, 0.15),         fixed=false,
                   description="ppsi: This is the something something.", texLabel="ppsi")

    ## TODO - ask Marc and Marco
    m <= parameter(:nu_l,     2.5975, (1e-5, 10.),   (1e-5, 10.),     Exponential(),    Normal(2, 0.75),            fixed=false,
                   description="ν_l: This is the something something.", texLabel="\nu_l")
    
    m <= parameter(:zeta_w,   0.9291, (1e-5, 0.999), (1e-5, 0.999),   SquareRoot(),     BetaAlt(0.5, 0.1),          fixed=false,
                   description="ζ_w: (1-ζ_w) is the probability with which households can freely choose wages in each period. With probability ζ_w, wages increase at a geometrically weighted average of the steady state rate of wage increases and last period's productivity times last period's inflation.",
                   texLabel="\zeta_w")

    #TODO: Something to do with intertemporal changes in wages? – Check in tex file
    m <= parameter(:iota_w,   0.2992, (1e-5, 0.999), (1e-5, 0.999),   SquareRoot(),     BetaAlt(0.5, 0.15),         fixed=false,
                   description="ι_w: This is the something something.", texLabel="\\iota_w")

    m <= parameter(:law,      1.5000,                                                                               fixed=true,
                   description="λ_w: The wage markup, which affects the elasticity of substitution between differentiated labor services.", texLabel="\\lambda_w")     # omit from parameter vector

    m <= parameter(:bet,      0.1402, (1e-5, 10.),   (1e-5, 10.),     Exponential(),    GammaAlt(0.25, 0.1),        fixed=false,
                   description="β: Discount rate.",       scaling = x -> (1 + x/100)\1, texLabel="\\beta ")

    m <= parameter(:ψ1,     1.3679, (1e-5, 10.),   (1e-5, 10.00),   Exponential(),    Normal(1.5, 0.25),          fixed=false,
                   description="ψ₁: Weight on inflation gap in monetary policy rule.", texLabel="\\psi_1")

    m <= parameter(:ψ2,     0.0388, (-0.5, 0.5),   (-0.5, 0.5),     Untransformed(),  Normal(0.12, 0.05),         fixed=false,
                   description="ψ₂: Weight on output gap in monetary policy rule.",
                   texLabel="\\psi_2")

    m <= parameter(:ψ3,     0.2464, (-0.5, 0.5),   (-0.5, 0.5),     Untransformed(),  Normal(0.12, 0.05),         fixed=false,
                   description="ψ₃: Weight on rate of change of output gap in the monetary policy rule.",
                   texLabel="\\psi_3")

    m <= parameter(:pistar,   0.5000, (1e-5, 10.),   (1e-5, 10.),     Exponential(),    GammaAlt(0.75, 0.4),        fixed=true,
                   description="π_star: The steady-state rate of inflation.",  scaling = x -> 1 + x/100,
                   texLabel="\\pi_*")   

    m <= parameter(:sigmac,   0.8719, (1e-5, 10.),   (1e-5, 10.),     Exponential(),    Normal(1.5, 0.37),          fixed=false,
                   description="σ_c: This is the something something.",
                   texLabel="\\sigma_{c}")
    
    m <= parameter(:rho,      0.7126, (1e-5, 0.999), (1e-5, 0.999),   SquareRoot(),     BetaAlt(0.75, 0.10),        fixed=false,
                   description="ρ: The degree of inertia in the monetary policy rule.",
                   texLabel="\\rho")
    
    m <= parameter(:epsp,     10.000,                                                                               fixed=true,
                   description="ϵ_p: This is the something something.",
                   texLabel="\\epsilon_{sp}")     # omit from parameter vector

    m <= parameter(:epsw,     10.000,                                                                               fixed=true,
                   description="ϵ_w: This is the something something.",
                   texLabel="\\epsilon_{sw}")     # omit from parameter vector

    # financial frictions parameters
    m <= parameter(:Fom,      0.0300, (1e-5, 0.99999), (1e-5, 0.99),  SquareRoot(),    BetaAlt(0.03, 0.01),         fixed=true,    scaling = x -> 1 - (1-x)^0.25,
                   description="F(ω): The cumulative distribution function of ω (idiosyncratic iid shock that increases or decreases entrepreneurs' capital).",
                   texLabel="F(\omega)")
    
    m <= parameter(:sprd,     1.7444, (0., 100.),      (1e-5, 0.),    Exponential(),   GammaAlt(2., 0.1),           fixed=false,
                   description="spr_*: This is the something something.",   scaling = x -> (1 + x/100)^0.25,
                   texLabel="spr_*")

    m <= parameter(:zeta_spb, 0.0559, (1e-5, 0.99999), (1e-5, 0.99),  SquareRoot(),    BetaAlt(0.05, 0.005),        fixed=false,
                   description="ζ_spb: The elasticity of the expected exess return on capital (or 'spread') with respect to leverage.",
                   texLabel="\\zeta_{spb}")
    
    m <= parameter(:gammstar, 0.9900, (1e-5, 0.99999), (1e-5, 0.99),  SquareRoot(),    BetaAlt(0.99, 0.002),        fixed=true,
                   description="γ_star: This is the something something.",
                   texLabel="\\gamma_*")

    # exogenous processes - level
    m <= parameter(:gam,      0.3673, (-5.0, 5.0),     (-5., 5.),     Untransformed(), Normal(0.4, 0.1),            fixed=false,
                   description="γ: The log of the steady-state growth rate of technology.",       scaling = x -> x/100, texLabel="\\gamma")

    m <= parameter(:Lmean,  -45.9364, (-1000., 1000.), (-1e3, 1e3),   Untransformed(), Normal(-45, 5),              fixed=false,
                   description="Lmean: This is the something something.",
                   texLabel="Lmean")

    m <= parameter(:gstar,    0.1800,                                                                               fixed=true,
                   description="g_star: This is the something something.",
                   texLabel="g_*")  # omit from parameter vector

    # exogenous processes - autocorrelation 
    m <= parameter(:ρ_g,      0.9863, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false,
                   description="ρ_g: The coefficient on the lag term in the exogenous government spending process, ln(g_t) = (1-ρ_g)*ln(g) + ρ_g*ln(g_{t-1} + ε_{g,t}.",
                   texLabel="\\rho_g")

    m <= parameter(:ρ_b,      0.9410, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false,
                   description="ρ_b: The coefficient on the lagged intertemporal preference shifter b in its AR(1) process.",
                   texLabel="\\rho_b")

    m <= parameter(:ρ_mu,     0.8735, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false,
                   description="ρ_μ: The coefficient on the lag term in the exogenous marginal efficiency of investment shock process.",
                   texLabel="\\rho_{\\mu}")

    m <= parameter(:ρ_z,      0.9446, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false,
                   description="ρ_z: The coefficient on the deviation of the lagged productivty growth rate from the steady-state productivity growth rate in the technology process.",
                   texLabel="\\rho_z")

    m <= parameter(:ρ_λ_f,    0.8827, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false,
                   description="ρ_λ_f: AR(1) coefficient on price mark-up shock process.",
                   texLabel="\\rho_{\\lambda_f}") 

    m <= parameter(:ρ_law,    0.3884, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false, description="ρ_λ_w: This is the something something.",           texLabel="\\rho_{\\lambda_f}")

    #monetary policy shock - see eqcond
    m <= parameter(:ρ_rm,     0.2135, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false, description="ρ_rm: This is the something something.",            texLabel="\\rho_{rm}")

    m <= parameter(:ρ_sigw,   0.9898, (1e-5, 0.99999), (1e-5, 0.99),  SquareRoot(),    BetaAlt(0.75, 0.15),         fixed=false,
                   description="ρ_σ_w: The standard deviation of entrepreneurs' capital productivity follows an exogenous process with mean ρ_σ_w. Innovations to the process are called _spread shocks_.",
                   texLabel="\\rho_{sigw}")

    # We're skipping this for now
    m <= parameter(:ρ_mue,    0.7500, (1e-5, 0.99999), (1e-5, 0.99),  SquareRoot(),    BetaAlt(0.75, 0.15),         fixed=true,
                   description="ρ_μ_e: Verification costs are a fraction μ_e of the amount the bank extracts from an entrepreneur in case of bankruptcy???? This doesn't seem right because μ_e isn't a process (p12 of PDF)",
                   texLabel="\\rho_{\\mu_e}")

    ## TODO
    m <= parameter(:ρ_gamm,   0.7500, (1e-5, 0.99999), (1e-5, 0.99),  SquareRoot(),    BetaAlt(0.75, 0.15),         fixed=true,  description="ρ_γ: AR(1) coefficient on XX process.",              texLabel="\\rho_{gamm}")    
    m <= parameter(:ρ_pist,   0.9900, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=true,  description="ρ_π_star: This is the something something.",         texLabel="\\rho_{pi}^*")   
    m <= parameter(:ρ_lr,     0.6936, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false, description="ρ_lr: This is the something something.",             texLabel="\\rho_{lr}")      
    m <= parameter(:ρ_zp,     0.8910, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false, description="ρ_zp: This is the something something.",             texLabel="\\rho_{z^p}")    
    m <= parameter(:ρ_tfp,    0.1953, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false, description="ρ_tfp: This is the something something.",            texLabel="\\rho_{tfp}")     
    m <= parameter(:ρ_gdpdef, 0.5379, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false, description="ρ_gdpdef: GDP deflator.",                            texLabel="\\rho_{gdpdef}")  
    m <= parameter(:ρ_pce,    0.2320, (1e-5, 0.999),   (1e-5, 0.999), SquareRoot(),    BetaAlt(0.5, 0.2),           fixed=false, description="ρ_pce: This is the something something.",            texLabel="\\rho_{pce}")     

    # exogenous processes - standard deviation
    m <= parameter(:σ_g,      2.5230, (1e-8, 5.),      (1e-8, 5.),    Exponential(),   RootInverseGamma(2., 0.10),  fixed=false,
                   description="σ_g: The standard deviation of the government spending process.",
                   texLabel="\\sigma_{g}")
    
    m <= parameter(:σ_b,      0.0292, (1e-8, 5.),      (1e-8, 5.),    Exponential(),   RootInverseGamma(2., 0.10),  fixed=false,
                   description="σ_b: This is the something something.",
                   texLabel="\\sigma_{b}")

    m <= parameter(:σ_mu,     0.4559, (1e-8, 5.),      (1e-8, 5.),    Exponential(),   RootInverseGamma(2., 0.10),  fixed=false,
                   description="σ_μ: The standard deviation of the exogenous marginal efficiency of investment shock process.",
                   texLabel="\\sigma_{\\mu}")

    ## TODO
    m <= parameter(:σ_z,      0.6742, (1e-8, 5.),      (1e-8, 5.),    Exponential(),   RootInverseGamma(2., 0.10),  fixed=false,
                   description="σ_z: This is the something something.",
                   texLabel="\\sigma_{z}")

    m <= parameter(:σ_laf,    0.1314, (1e-8, 5.),      (1e-8, 5.),    Exponential(),   RootInverseGamma(2., 0.10),  fixed=false,
                   description="σ_λ_f: The mean of the process that generates the price elasticity of the composite good.  Specifically, the elasticity is (1+λ_{f,t})/(λ_{f_t}).",
                   texLabel="\\sigma_{\\lambda_f}")

    ## TODO
    m <= parameter(:σ_law,    0.3864, (1e-8, 5.),      (1e-8, 5.),    Exponential(),   RootInverseGamma(2., 0.10),  fixed=false,
                   description="σ_λ_w: This is the something something.",
                   texLabel="\\sigma_{\\lambda_w}")

    ## TODO
    m <= parameter(:σ_rm,     0.2380, (1e-8, 5.),      (1e-8, 5.),    Exponential(),   RootInverseGamma(2., 0.10),  fixed=false,
                   description="σ_rm: This is the something something.",
                   texLabel="\\sigma_{rm}")
    
    m <= parameter(:σ_sigw,   0.0428, (1e-7,100.),     (1e-5, 0.),    Exponential(),   RootInverseGamma(4., 0.05),  fixed=false,
                   description="σ_σ_w: The standard deviation of entrepreneurs' capital productivity follows an exogenous process with standard deviation σ_σ_w.",
                   texLabel="\\sigma_{sigw}")
    
    m <= parameter(:σ_mue,    0.0000, (1e-7,100.),     (1e-5, 0.),    Exponential(),   RootInverseGamma(4., 0.05),  fixed=true,  description="σ_μ_e: This is the something something.",           texLabel="\\sigma_{mue}")
    m <= parameter(:σ_gamm,   0.0000, (1e-7,100.),     (1e-5, 0.),    Exponential(),   RootInverseGamma(4., 0.01),  fixed=true,  description="σ_γ: This is the something something.",             texLabel="\\sigma_{gamm}")    
    m <= parameter(:σ_pist,   0.0269, (1e-8, 5.),      (1e-8, 5.),    Exponential(),   RootInverseGamma(6., 0.03),  fixed=false, description="σ_π_star: This is the something something.",        texLabel="\\sigma_{pi}^*")   
    m <= parameter(:σ_lr,     0.1766, (1e-8,10.),      (1e-8, 5.),    Exponential(),   RootInverseGamma(2., 0.75),  fixed=false, description="σ_lr: This is the something something to do with long run inflation expectations.",
                   texLabel="\\sigma_{lr}")      
    m <= parameter(:σ_zp,     0.1662, (1e-8, 5.),      (1e-8, 5.),    Exponential(),   RootInverseGamma(2., 0.10),  fixed=false, description="σ_zp: This is the something something.",            texLabel="\\sigma_{z^p}")    
    m <= parameter(:σ_tfp,    0.9391, (1e-8, 5.),      (1e-8, 5.),    Exponential(),   RootInverseGamma(2., 0.10),  fixed=false, description="σ_tfp: This is the something something.",           texLabel="\\sigma_{tfp}")     
    m <= parameter(:σ_gdpdef, 0.1575, (1e-8, 5.),      (1e-8, 5.),    Exponential(),   RootInverseGamma(2., 0.10),  fixed=false, description="σ_gdpdef: This is the something something.",        texLabel="\\sigma_{gdpdef}")  
    m <= parameter(:σ_pce,    0.0999, (1e-8, 5.),      (1e-8, 5.),    Exponential(),   RootInverseGamma(2., 0.10),  fixed=false, description="σ_pce: This is the something something.",           texLabel="\\sigma_{pce}")     

    # standard deviations of the anticipated policy shocks
    for i = 1:num_anticipated_shocks_padding(m)
        if i < 13
            m <= parameter(symbol("σ_rm$i"), .2, (1e-7, 100.), (1e-5, 0.), Exponential(), RootInverseGamma(4., .2), fixed=false, description="σ_rm$i: This is the something something.", texLabel=@sprintf("\\sigma_ant{%d}",i))
        else
            m <= parameter(symbol("σ_rm$i"), .0, (1e-7, 100.), (1e-5, 0.), Exponential(), RootInverseGamma(4., .2), fixed=true,  description="σ_rm$i: This is the something something.", texLabel=@sprintf("\\sigma_ant{%d}",i))
        end
    end

    ## TODO - look at etas in eqcond and figure out what they are, then confirm with Marc and Marco
    m <= parameter(:eta_gz,       0.8400, (1e-5, 0.999), (1e-5, 0.999), SquareRoot(),  BetaAlt(0.50, 0.20),         fixed=false, description="η_gz: Has to do with correlation of g and z shocks.",  texLabel="\\eta_{gz}")        
    m <= parameter(:eta_laf,      0.7892, (1e-5, 0.999), (1e-5, 0.999), SquareRoot(),  BetaAlt(0.50, 0.20),         fixed=false, description="η_λ_f: This is the something something.", texLabel="\\eta_{\\lambda_f}")
    m <= parameter(:eta_law,      0.4226, (1e-5, 0.999), (1e-5, 0.999), SquareRoot(),  BetaAlt(0.50, 0.20),         fixed=false, description="η_λ_w: AR(2) coefficient on wage markup shock process.", texLabel="\\eta_{\\lambda_w}")

    m <= parameter(:modelalp_ind, 0.0000, (0.000, 1.000), (0., 0.),
                   Untransformed(), BetaAlt(0.50, 0.20), fixed=true,
                   description="modelα_ind: Indicates whether to use the model's endogenous α in the capacity utilization adjustment of total factor productivity.",
                   texLabel="i_{\\alpha}^model")
    
    m <= parameter(:gamm_gdpdef,  1.0354, (-10., 10.), (-10., -10.),  Untransformed(), Normal(1.00, 2.),            fixed=false, description="γ_gdpdef: This is the something something.",   texLabel="\\Gamma_{gdpdef}")
    m <= parameter(:del_gdpdef,   0.0181, (-9.1, 9.1), (-10., -10.),  Untransformed(), Normal(0.00, 2.),            fixed=false, description="δ_gdpdef: This is the something something.",   texLabel="\\delta_{gdpdef}")

    # steady states
    m <= parameter(:zstar,        NaN, description="steady-state growth rate of productivity", texLabel="\\z_*")
    m <= parameter(:rstar,        NaN, description="steady-state something something", texLabel="\\r_*")
    m <= parameter(:Rstarn,       NaN, description="steady-state something something", texLabel="\\R_*_n")
    m <= parameter(:rkstar,       NaN, description="steady-state something something", texLabel="\\BLAH")
    m <= parameter(:wstar,        NaN, description="steady-state something something", texLabel="\\w_*")
    m <= parameter(:Lstar,        NaN, description="steady-state something something", texLabel="\\L_*") 
    m <= parameter(:kstar,        NaN, description="Effective capital that households rent to firms in the steady state.", texLabel="\\k_*")
    m <= parameter(:kbarstar,     NaN, description="Total capital owned by households in the steady state.", texLabel="\\bar{k}_*")
    m <= parameter(:istar,        NaN, description="Steady-state investment;", texLabel="\\i_*")
    m <= parameter(:ystar,        NaN, description="steady-state something something", texLabel="\\y_*")
    m <= parameter(:cstar,        NaN, description="steady-state something something", texLabel="\\c_*")
    m <= parameter(:wl_c,         NaN, description="steady-state something something", texLabel="\\wl_c")
    m <= parameter(:nstar,        NaN, description="steady-state something something", texLabel="\\n_*")
    m <= parameter(:vstar,        NaN, description="steady-state something something", texLabel="\\v_*")
    m <= parameter(:zeta_spsigw,  NaN, description="steady-state something something", texLabel="\\zeta_{sp_σ_w}")
    m <= parameter(:zeta_spmue,   NaN, description="steady-state something something", texLabel="\\zeta_{sp_μ_e}")
    m <= parameter(:zeta_nRk,     NaN, description="steady-state something something", texLabel="\\zeta_{n_R_k}")
    m <= parameter(:zeta_nR,      NaN, description="steady-state something something", texLabel="\\BLAH")
    m <= parameter(:zeta_nqk,     NaN, description="steady-state something something", texLabel="\\BLAH")
    m <= parameter(:zeta_nn,      NaN, description="steady-state something something", texLabel="\\BLAH")
    m <= parameter(:zeta_nmue,    NaN, description="steady-state something something", texLabel="\\BLAH")
    m <= parameter(:zeta_nsigw,   NaN, description="steady-state something something", texLabel="\\BLAH")

    initialise_model_indices!(m)
    steadystate!(m)
    return m
end

# functions that are used to compute financial frictions
# steady-state values from parameter values
@inline function ζ_spb_fn(z, σ, sprd)
    zetaratio = ζ_bω_fn(z, σ, sprd)/ζ_zω_fn(z, σ, sprd)
    nk = nk_fn(z, σ, sprd)
    return -zetaratio/(1-zetaratio)*nk/(1-nk)
end

@inline function ζ_bω_fn(z, σ, sprd)
    nk          = nk_fn(z, σ, sprd)
    μstar       = μ_fn(z, σ, sprd)
    ωstar       = ω_fn(z, σ)
    Γstar       = Γ_fn(z, σ)
    Gstar       = G_fn(z, σ)
    dΓ_dωstar   = dΓ_dω_fn(z)
    dG_dωstar   = dG_dω_fn(z, σ)
    d2Γ_dω2star = d2Γ_dω2_fn(z, σ)
    d2G_dω2star = d2G_dω2_fn(z, σ)
    return ωstar*μstar*nk*(d2Γ_dω2star*dG_dωstar - d2G_dω2star*dΓ_dωstar)/
        (dΓ_dωstar - μstar*dG_dωstar)^2/sprd/(1 - Γstar + dΓ_dωstar*(Γstar - μstar*Gstar)/
            (dΓ_dωstar - μstar*dG_dωstar))
end

@inline function ζ_zω_fn(z, σ, sprd)
    μstar = μ_fn(z, σ, sprd)
    return ω_fn(z, σ)*(dΓ_dω_fn(z) - μstar*dG_dω_fn(z, σ))/
        (Γ_fn(z, σ) - μstar*G_fn(z, σ))
end

nk_fn(z, σ, sprd) = 1 - (Γ_fn(z, σ) - μ_fn(z, σ, sprd)*G_fn(z, σ))*sprd
μ_fn(z, σ, sprd)  =
    (1 - 1/sprd)/(dG_dω_fn(z, σ)/dΓ_dω_fn(z)*(1 - Γ_fn(z, σ)) + G_fn(z, σ))
ω_fn(z, σ)        = exp(σ*z - σ^2/2)
G_fn(z, σ)        = cdf(Normal(), z-σ)
Γ_fn(z, σ)        = ω_fn(z, σ)*(1 - cdf(Normal(), z)) + cdf(Normal(), z-σ)
dG_dω_fn(z, σ)    = pdf(Normal(), z)/σ
d2G_dω2_fn(z, σ)  = -z*pdf(Normal(), z)/ω_fn(z, σ)/σ^2
dΓ_dω_fn(z)       = 1 - cdf(Normal(), z)
d2Γ_dω2_fn(z, σ)  = -pdf(Normal(), z)/ω_fn(z, σ)/σ
dG_dσ_fn(z, σ)    = -z*pdf(Normal(), z-σ)/σ
d2G_dωdσ_fn(z, σ) = -pdf(Normal(), z)*(1 - z*(z-σ))/σ^2
dΓ_dσ_fn(z, σ)    = -pdf(Normal(), z-σ)
d2Γ_dωdσ_fn(z, σ) = (z/σ-1)*pdf(Normal(), z)

# (Re)calculates steady-state values
function steadystate!(m::Model990)
    m[:zstar]    = log(1+m[:gam]) + m[:alp]/(1-m[:alp])*log(m[:ups])
    m[:rstar]    = exp(m[:sigmac]*m[:zstar]) / m[:bet]
    m[:Rstarn]   = 100*(m[:rstar]*m[:pistar] - 1)
    m[:rkstar]   = m[:sprd]*m[:rstar]*m[:ups] - (1-m[:del])
    m[:wstar]    = (m[:alp]^m[:alp] * (1-m[:alp])^(1-m[:alp]) * m[:rkstar]^(-m[:alp]) / m[:Bigphi])^(1/(1-m[:alp]))
    m[:Lstar]    = 1.
    m[:kstar]    = (m[:alp]/(1-m[:alp])) * m[:wstar] * m[:Lstar] / m[:rkstar]
    m[:kbarstar] = m[:kstar] * (1+m[:gam]) * m[:ups]^(1 / (1-m[:alp]))
    m[:istar]    = m[:kbarstar] * (1-((1-m[:del])/((1+m[:gam]) * m[:ups]^(1/(1-m[:alp])))))
    m[:ystar]    = (m[:kstar]^m[:alp]) * (m[:Lstar]^(1-m[:alp])) / m[:Bigphi]
    m[:cstar]    = (1-m[:gstar])*m[:ystar] - m[:istar]
    m[:wl_c]     = (m[:wstar]*m[:Lstar])/(m[:cstar]*m[:law])

    # FINANCIAL FRICTIONS ADDITIONS
    # solve for sigmaomegastar and zomegastar
    zwstar = quantile(Normal(), m[:Fom].value)
    sigwstar = fzero(sigma -> ζ_spb_fn(zwstar, sigma, m[:sprd]) - m[:zeta_spb], 0.5)

    # evaluate omegabarstar
    omegabarstar = ω_fn(zwstar, sigwstar)

    # evaluate all BGG function elasticities
    Gstar                   = G_fn(zwstar, sigwstar)
    Gammastar               = Γ_fn(zwstar, sigwstar)
    dGdomegastar            = dG_dω_fn(zwstar, sigwstar)
    d2Gdomega2star          = d2G_dω2_fn(zwstar, sigwstar)
    dGammadomegastar        = dΓ_dω_fn(zwstar)
    d2Gammadomega2star      = d2Γ_dω2_fn(zwstar, sigwstar)
    dGdsigmastar            = dG_dσ_fn(zwstar, sigwstar)
    d2Gdomegadsigmastar     = d2G_dωdσ_fn(zwstar, sigwstar)
    dGammadsigmastar        = dΓ_dσ_fn(zwstar, sigwstar)
    d2Gammadomegadsigmastar = d2Γ_dωdσ_fn(zwstar, sigwstar)

    # evaluate mu, nk, and Rhostar
    muestar       = μ_fn(zwstar, sigwstar, m[:sprd])
    nkstar        = nk_fn(zwstar, sigwstar, m[:sprd])
    Rhostar       = 1/nkstar - 1

    # evaluate wekstar and vkstar
    wekstar       = (1-m[:gammstar]/m[:bet])*nkstar - m[:gammstar]/m[:bet]*(m[:sprd]*(1-muestar*Gstar) - 1)
    vkstar        = (nkstar-wekstar)/m[:gammstar]

    # evaluate nstar and vstar
    m[:nstar]       = nkstar*m[:kstar]
    m[:vstar]       = vkstar*m[:kstar]

    # a couple of combinations
    GammamuG      = Gammastar - muestar*Gstar
    GammamuGprime = dGammadomegastar - muestar*dGdomegastar

    # elasticities wrt omegabar
    zeta_bw       = ζ_bω_fn(zwstar, sigwstar, m[:sprd])
    zeta_zw       = ζ_zω_fn(zwstar, sigwstar, m[:sprd])
    zeta_bw_zw    = zeta_bw/zeta_zw

    # elasticities wrt sigw
    zeta_bsigw      = sigwstar * (((1 - muestar*dGdsigmastar/dGammadsigmastar) /
        (1 - muestar*dGdomegastar/dGammadomegastar) - 1)*dGammadsigmastar*m[:sprd] + muestar*nkstar*
            (dGdomegastar*d2Gammadomegadsigmastar - dGammadomegastar*d2Gdomegadsigmastar)/GammamuGprime^2) /
                ((1 - Gammastar)*m[:sprd] + dGammadomegastar/GammamuGprime*(1-nkstar))
    zeta_zsigw      = sigwstar * (dGammadsigmastar - muestar*dGdsigmastar) / GammamuG
    m[:zeta_spsigw] = (zeta_bw_zw*zeta_zsigw - zeta_bsigw) / (1-zeta_bw_zw)

    # elasticities wrt mue
    zeta_bmue      = muestar * (nkstar*dGammadomegastar*dGdomegastar/GammamuGprime+dGammadomegastar*Gstar*m[:sprd]) /
        ((1-Gammastar)*GammamuGprime*m[:sprd] + dGammadomegastar*(1-nkstar))
    zeta_zmue      = -muestar*Gstar/GammamuG
    m[:zeta_spmue] = (zeta_bw_zw*zeta_zmue - zeta_bmue) / (1-zeta_bw_zw)

    # some ratios/elasticities
    Rkstar        = m[:sprd]*m[:pistar]*m[:rstar] # (rkstar+1-delta)/ups*pistar
    zeta_gw       = dGdomegastar/Gstar*omegabarstar
    zeta_Gsigw    = dGdsigmastar/Gstar*sigwstar

    # elasticities for the net worth evolution
    m[:zeta_nRk]    = m[:gammstar]*Rkstar/m[:pistar]/exp(m[:zstar])*(1+Rhostar)*(1 - muestar*Gstar*(1 - zeta_gw/zeta_zw))
    m[:zeta_nR]     = m[:gammstar]/m[:bet]*(1+Rhostar)*(1 - nkstar + muestar*Gstar*m[:sprd]*zeta_gw/zeta_zw)
    m[:zeta_nqk]    = m[:gammstar]*Rkstar/m[:pistar]/exp(m[:zstar])*(1+Rhostar)*(1 - muestar*Gstar*(1+zeta_gw/zeta_zw/Rhostar)) - m[:gammstar]/m[:bet]*(1+Rhostar)
    m[:zeta_nn]     = m[:gammstar]/m[:bet] + m[:gammstar]*Rkstar/m[:pistar]/exp(m[:zstar])*(1+Rhostar)*muestar*Gstar*zeta_gw/zeta_zw/Rhostar
    m[:zeta_nmue]   = m[:gammstar]*Rkstar/m[:pistar]/exp(m[:zstar])*(1+Rhostar)*muestar*Gstar*(1 - zeta_gw*zeta_zmue/zeta_zw)
    m[:zeta_nsigw]  = m[:gammstar]*Rkstar/m[:pistar]/exp(m[:zstar])*(1+Rhostar)*muestar*Gstar*(zeta_Gsigw-zeta_gw/zeta_zw*zeta_zsigw)

    return m
end

# Creates the proper directory structure for input and output files
function createSaveDirectories(savepath::String)

    paths = [savepath,
             joinpath(savepath, "input_data"),
             joinpath(savepath, "output_data"),
             joinpath(savepath, "logs"),
             joinpath(savepath, "results"),
             joinpath(savepath, "results/tables"),
             joinpath(savepath, "results/plots")]

    for path in paths
        if(!ispath(path))
            mkdir(path)
            println("created $path")
        end
    end

end

